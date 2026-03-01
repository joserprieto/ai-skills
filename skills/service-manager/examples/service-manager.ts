#!/usr/bin/env npx tsx
/**
 * Service Manager for Slidev Presentations
 *
 * Manages development and preview servers with:
 * - Background execution by default
 * - Log rotation and management
 * - Clean shutdown on SIGINT/SIGTERM
 * - Foreground mode with --fg flag
 *
 * Usage:
 *   npx tsx scripts/service-manager.ts <command> [service] [options]
 *
 * Commands:
 *   start     Start service(s) - background by default
 *   stop      Stop service(s)
 *   status    Show service status
 *   tail      Tail service logs
 *   logs      Log management
 *
 * Services:
 *   dev, preview, --all
 *
 * Options:
 *   --fg       Run in foreground (not background)
 *   --detail   Show detailed status
 *   --rotate   Rotate logs
 *   --verbose  Verbose output
 */

import {
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
  statSync,
  renameSync,
  openSync,
  closeSync,
} from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync, type ChildProcess } from 'node:child_process';

// ==============================================================================
// Configuration
// ==============================================================================

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = process.env.ROOT_DIR || resolve(__dirname, '..');
const STATE_DIR = process.env.STATE_DIR || join(ROOT_DIR, '.state');
const LOGS_DIR = process.env.LOGS_DIR || join(ROOT_DIR, '.logs');

// Slidev-specific configuration
const SLIDES_FILE = process.env.SLIDES_FILE || 'slides.md';
const SLIDEV_OPEN = process.env.SLIDEV_OPEN !== 'false'; // open browser by default
const SLIDEV_REMOTE = process.env.SLIDEV_REMOTE || ''; // --remote flag for network access

// Log rotation settings
const LOG_MAX_SIZE = parseSize(process.env.LOG_MAX_SIZE || '10M');
const LOG_MAX_FILES = parseInt(process.env.LOG_MAX_FILES || '5', 10);

// ==============================================================================
// Types
// ==============================================================================

interface ServiceConfig {
  name: string;
  displayName: string;
  port: number;
  portEnvVar: string;
  pidFile: string;
  logFile: string;
  cwd: string;
  command: string[];
  healthUrl: string;
}

interface ServiceStatus {
  running: boolean;
  pid: number | null;
  port: number;
  uptime: string | null;
  logSize: string | null;
  healthy: boolean | null;
}

interface PidInfo {
  pid: number;
  startTime: number;
}

// ==============================================================================
// Utilities
// ==============================================================================

function parseSize(size: string): number {
  const match = size.match(/^(\d+)([KMG])?$/i);
  if (!match || !match[1]) return 10 * 1024 * 1024; // 10MB default
  const num = parseInt(match[1], 10);
  const unit = (match[2] ?? '').toUpperCase();
  switch (unit) {
    case 'K':
      return num * 1024;
    case 'M':
      return num * 1024 * 1024;
    case 'G':
      return num * 1024 * 1024 * 1024;
    default:
      return num;
  }
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}K`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)}M`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)}G`;
}

function formatUptime(startTime: number): string {
  const seconds = Math.floor((Date.now() - startTime) / 1000);
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
  const hours = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  return `${hours}h ${mins}m`;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ==============================================================================
// Colors
// ==============================================================================

const c = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
};

function log(msg: string): void {
  console.log(msg);
}
function logOk(msg: string): void {
  console.log(`${c.green}\u2713${c.reset} ${msg}`);
}
function logErr(msg: string): void {
  console.log(`${c.red}\u2717${c.reset} ${msg}`);
}
function logInfo(msg: string): void {
  console.log(`${c.blue}\u2139${c.reset} ${msg}`);
}
function logWarn(msg: string): void {
  console.log(`${c.yellow}\u26A0${c.reset} ${msg}`);
}
function logHeader(msg: string): void {
  console.log(`\n${c.bold}${c.cyan}\u2501\u2501\u2501 ${msg} \u2501\u2501\u2501${c.reset}\n`);
}

// ==============================================================================
// Environment
// ==============================================================================

function loadEnv(): void {
  const envPath = join(ROOT_DIR, '.env.local');
  if (existsSync(envPath)) {
    const content = readFileSync(envPath, 'utf-8');
    for (const line of content.split('\n')) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        const value = valueParts.join('=');
        if (key && value !== undefined && !process.env[key]) {
          process.env[key] = value;
        }
      }
    }
  }
}

function getPort(envVar: string, defaultPort: number): number {
  return parseInt(process.env[envVar] || String(defaultPort), 10);
}

// ==============================================================================
// Services Configuration
// ==============================================================================

function getServices(): Record<string, ServiceConfig> {
  const devPort = getPort('DEV_PORT', 3030);
  const previewPort = getPort('PREVIEW_PORT', 3031);

  // Build dev command with conditional flags
  const devCommand = ['pnpm', 'slidev', SLIDES_FILE, '--port', String(devPort)];
  if (SLIDEV_OPEN) devCommand.push('--open');
  if (SLIDEV_REMOTE) devCommand.push('--remote', SLIDEV_REMOTE);

  return {
    dev: {
      name: 'dev',
      displayName: 'Slidev Dev (HMR)',
      port: devPort,
      portEnvVar: 'DEV_PORT',
      pidFile: join(STATE_DIR, 'dev.pid'),
      logFile: join(LOGS_DIR, 'dev.log'),
      cwd: ROOT_DIR,
      command: devCommand,
      healthUrl: 'http://localhost:{port}/',
    },
    preview: {
      name: 'preview',
      displayName: 'Slidev Preview (Build)',
      port: previewPort,
      portEnvVar: 'PREVIEW_PORT',
      pidFile: join(STATE_DIR, 'preview.pid'),
      logFile: join(LOGS_DIR, 'preview.log'),
      cwd: ROOT_DIR,
      command: ['pnpm', 'run', 'preview'],
      healthUrl: 'http://localhost:{port}/',
    },
  };
}

// ==============================================================================
// Directory Management
// ==============================================================================

function ensureDirs(): void {
  if (!existsSync(STATE_DIR)) mkdirSync(STATE_DIR, { recursive: true });
  if (!existsSync(LOGS_DIR)) mkdirSync(LOGS_DIR, { recursive: true });
}

// ==============================================================================
// PID Management
// ==============================================================================

function readPid(service: ServiceConfig): PidInfo | null {
  if (existsSync(service.pidFile)) {
    try {
      const content = readFileSync(service.pidFile, 'utf-8').trim();
      const parts = content.split(':');
      const pidStr = parts[0] ?? '';
      const startTimeStr = parts[1] ?? '0';
      const pid = parseInt(pidStr, 10);
      const startTime = parseInt(startTimeStr, 10);
      return isNaN(pid) ? null : { pid, startTime: startTime || Date.now() };
    } catch {
      return null;
    }
  }
  return null;
}

function writePid(service: ServiceConfig, pid: number): void {
  writeFileSync(service.pidFile, `${pid}:${Date.now()}`);
}

function removePid(service: ServiceConfig): void {
  if (existsSync(service.pidFile)) {
    rmSync(service.pidFile);
  }
}

// ==============================================================================
// Process Management
// ==============================================================================

function isProcessRunning(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

/**
 * Get all child PIDs of a process recursively
 */
function getChildPids(pid: number): number[] {
  const children: number[] = [];
  try {
    const result = spawnSync('pgrep', ['-P', String(pid)], { encoding: 'utf-8' });
    if (result.status === 0 && result.stdout) {
      const pids = result.stdout
        .trim()
        .split('\n')
        .filter((s) => s.length > 0)
        .map((s) => parseInt(s, 10))
        .filter((p) => !isNaN(p));

      for (const childPid of pids) {
        children.push(childPid);
        children.push(...getChildPids(childPid));
      }
    }
  } catch {
    // pgrep failed or not available
  }
  return children;
}

/**
 * Kill a process and all its descendants
 */
function killProcessTree(pid: number, signal: NodeJS.Signals = 'SIGTERM'): void {
  const children = getChildPids(pid);

  // Kill children in reverse order (deepest first)
  for (const childPid of children.reverse()) {
    try {
      if (isProcessRunning(childPid)) {
        process.kill(childPid, signal);
      }
    } catch {
      // Process may have already exited
    }
  }

  // Kill the parent process
  try {
    if (isProcessRunning(pid)) {
      process.kill(pid, signal);
    }
  } catch {
    // Process may have already exited
  }
}

function getProcessOnPort(port: number): number | null {
  try {
    const result = spawnSync('lsof', ['-ti', `tcp:${port}`], { encoding: 'utf-8' });
    if (result.status === 0 && result.stdout) {
      const firstLine = result.stdout.trim().split('\n')[0] ?? '';
      const pid = parseInt(firstLine, 10);
      return isNaN(pid) ? null : pid;
    }
  } catch {
    // lsof not available
  }
  return null;
}

function stopProcess(pid: number, timeout = 5000): boolean {
  try {
    const allPids = [pid, ...getChildPids(pid)];

    // Try graceful SIGTERM first
    killProcessTree(pid, 'SIGTERM');

    const start = Date.now();
    while (Date.now() - start < timeout) {
      const anyRunning = allPids.some((p) => isProcessRunning(p));
      if (!anyRunning) return true;

      const sleepResult = spawnSync('sleep', ['0.1']);
      if (sleepResult.status !== 0) break;
    }

    // Force kill any survivors with SIGKILL
    for (const p of allPids) {
      if (isProcessRunning(p)) {
        try {
          process.kill(p, 'SIGKILL');
        } catch {
          // Process may have exited between check and kill
        }
      }
    }

    spawnSync('sleep', ['0.5']);
    return !allPids.some((p) => isProcessRunning(p));
  } catch {
    return !isProcessRunning(pid);
  }
}

// ==============================================================================
// Log Management
// ==============================================================================

function rotateLog(logFile: string): void {
  if (!existsSync(logFile)) return;

  for (let i = LOG_MAX_FILES - 1; i >= 1; i--) {
    const oldFile = `${logFile}.${i}`;
    const newFile = `${logFile}.${i + 1}`;
    if (existsSync(oldFile)) {
      if (i === LOG_MAX_FILES - 1) {
        rmSync(oldFile);
      } else {
        renameSync(oldFile, newFile);
      }
    }
  }

  if (existsSync(logFile)) {
    renameSync(logFile, `${logFile}.1`);
  }
}

function shouldRotate(logFile: string): boolean {
  if (!existsSync(logFile)) return false;
  const stats = statSync(logFile);
  return stats.size >= LOG_MAX_SIZE;
}

function getLogSize(logFile: string): number {
  if (!existsSync(logFile)) return 0;
  return statSync(logFile).size;
}

// ==============================================================================
// Health Check
// ==============================================================================

async function checkHealth(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, {
      method: 'GET',
      signal: AbortSignal.timeout(2000),
    });
    return response.ok;
  } catch {
    return false;
  }
}

// ==============================================================================
// Service Status
// ==============================================================================

function getServiceStatus(service: ServiceConfig): ServiceStatus {
  const pidInfo = readPid(service);
  let running = false;
  let pid: number | null = null;

  if (pidInfo && isProcessRunning(pidInfo.pid)) {
    running = true;
    pid = pidInfo.pid;
  } else {
    if (pidInfo) removePid(service);

    const portPid = getProcessOnPort(service.port);
    if (portPid) {
      running = true;
      pid = portPid;
    }
  }

  const logSize = getLogSize(service.logFile);

  return {
    running,
    pid,
    port: service.port,
    uptime: pidInfo && running ? formatUptime(pidInfo.startTime) : null,
    logSize: logSize > 0 ? formatSize(logSize) : null,
    healthy: null,
  };
}

async function getServiceStatusWithHealth(service: ServiceConfig): Promise<ServiceStatus> {
  const status = getServiceStatus(service);
  if (status.running) {
    const healthUrl = service.healthUrl.replace('{port}', String(service.port));
    status.healthy = await checkHealth(healthUrl);
  }
  return status;
}

// ==============================================================================
// Commands
// ==============================================================================

const runningProcesses: ChildProcess[] = [];

function setupSignalHandlers(): void {
  const cleanup = () => {
    log('\n');
    logInfo('Shutting down...');
    for (const proc of runningProcesses) {
      if (proc.pid && isProcessRunning(proc.pid)) {
        killProcessTree(proc.pid, 'SIGTERM');
      }
    }
    process.exit(0);
  };

  process.on('SIGINT', cleanup);
  process.on('SIGTERM', cleanup);
}

async function startService(
  service: ServiceConfig,
  options: { foreground: boolean; verbose: boolean }
): Promise<boolean> {
  const status = getServiceStatus(service);

  if (status.running) {
    logInfo(
      `${service.displayName} is already running (PID: ${status.pid}, port: ${service.port})`
    );
    return true;
  }

  logInfo(`Starting ${service.displayName} on port ${service.port}...`);

  const env: Record<string, string> = { ...process.env } as Record<string, string>;
  env[service.portEnvVar] = String(service.port);

  if (options.foreground) {
    const cmd = service.command[0];
    if (!cmd) {
      logErr(`Invalid command for ${service.displayName}`);
      return false;
    }
    const proc = spawn(cmd, service.command.slice(1), {
      cwd: service.cwd,
      env,
      stdio: 'inherit',
    });

    if (proc.pid) {
      writePid(service, proc.pid);
    }
    runningProcesses.push(proc);

    logOk(`${service.displayName} started in foreground (PID: ${proc.pid ?? 'unknown'})`);

    await new Promise<void>((resolve) => proc.on('exit', () => resolve()));
    removePid(service);
    logInfo(`${service.displayName} exited`);
    return true;
  } else {
    if (shouldRotate(service.logFile)) {
      rotateLog(service.logFile);
    }

    const startMsg = `\n${'='.repeat(60)}\n[${new Date().toISOString()}] Starting ${service.displayName}\n${'='.repeat(60)}\n\n`;
    writeFileSync(service.logFile, startMsg, { flag: 'a' });

    // Open log file for appending
    const logFd = openSync(service.logFile, 'a');

    const cmd = service.command[0];
    if (!cmd) {
      logErr(`Invalid command for ${service.displayName}`);
      closeSync(logFd);
      return false;
    }

    // Spawn detached process with output redirected to log file
    // Use 'pipe' for stdin to keep process alive (some tools exit without TTY)
    const proc = spawn(cmd, service.command.slice(1), {
      cwd: service.cwd,
      env: { ...env, FORCE_COLOR: '0', CI: 'true' },
      detached: true,
      stdio: ['pipe', logFd, logFd],
    });

    // Close stdin to prevent blocking but after process starts
    proc.stdin?.end();

    // Unref to allow parent to exit independently
    proc.unref();

    const pid = proc.pid;
    if (!pid) {
      logErr(`Failed to get PID for ${service.displayName}`);
      closeSync(logFd);
      return false;
    }

    writePid(service, pid);
    closeSync(logFd);

    // Wait for service to start
    await sleep(2000);

    const portPid = getProcessOnPort(service.port);
    if (portPid || isProcessRunning(pid)) {
      logOk(`${service.displayName} started (PID: ${pid}, port: ${service.port})`);
      logInfo(`Logs: ${service.logFile}`);
      return true;
    } else {
      logErr(`Failed to start ${service.displayName}`);
      removePid(service);
      return false;
    }
  }
}

async function stopService(service: ServiceConfig): Promise<boolean> {
  const status = getServiceStatus(service);

  if (!status.running) {
    logInfo(`${service.displayName} is not running`);
    removePid(service);
    return true;
  }

  logInfo(`Stopping ${service.displayName} (PID: ${status.pid})...`);

  if (status.pid && stopProcess(status.pid)) {
    removePid(service);
    logOk(`${service.displayName} stopped`);
    return true;
  } else {
    logErr(`Failed to stop ${service.displayName}`);
    return false;
  }
}

async function showStatus(services: ServiceConfig[], detailed: boolean): Promise<void> {
  logHeader('Service Status');

  const statuses = await Promise.all(services.map((s) => getServiceStatusWithHealth(s)));

  const PAD = 28;

  for (let i = 0; i < services.length; i++) {
    const svc = services[i]!;
    const status = statuses[i]!;

    if (status.running) {
      const healthIcon =
        status.healthy === null
          ? ''
          : status.healthy
            ? `${c.green}\u25CF${c.reset}`
            : `${c.red}\u25CF${c.reset}`;
      const url = `http://localhost:${status.port}`;
      log(
        `  ${c.green}\u25CF${c.reset} ${c.bold}${svc.displayName.padEnd(PAD)}${c.reset} ` +
          `${c.green}Running${c.reset}  ${c.cyan}${url}${c.reset} ${healthIcon}`
      );

      if (detailed) {
        const pid = `PID: ${status.pid}`;
        const uptime = `Uptime: ${status.uptime ?? 'unknown'}`;
        const logSize = `Log: ${status.logSize ?? '0'}`;
        const logPath = svc.logFile;
        log(`    ${c.dim}${pid}  ${uptime}  ${logSize}${c.reset}`);
        log(`    ${c.dim}Log file: ${logPath}${c.reset}`);
      }
    } else {
      log(`  ${c.dim}\u25CB ${svc.displayName.padEnd(PAD)} Stopped${c.reset}`);

      if (detailed) {
        log(`    ${c.dim}Port: ${svc.port}  Log file: ${svc.logFile}${c.reset}`);
      }
    }
  }

  log('');

  if (detailed) {
    log(`  ${c.dim}\u2500\u2500\u2500 Environment \u2500\u2500\u2500${c.reset}`);
    log(`  ${c.dim}Slides:${c.reset}     ${SLIDES_FILE}`);
    log(`  ${c.dim}State Dir:${c.reset}  ${STATE_DIR}`);
    log(`  ${c.dim}Logs Dir:${c.reset}   ${LOGS_DIR}`);
    log('');
  }
}

async function tailLogs(services: ServiceConfig[]): Promise<void> {
  const running = services.filter((s) => getServiceStatus(s).running);
  if (running.length === 0) {
    logWarn('No services are running');
    return;
  }

  const logsExist = running.filter((s) => existsSync(s.logFile));
  if (logsExist.length === 0) {
    logWarn('No log files found');
    return;
  }

  logHeader(`Tailing Logs (${logsExist.map((s) => s.name).join(', ')})`);
  logInfo('Press Ctrl+C to stop\n');

  const logFiles = logsExist.map((s) => s.logFile);
  const tailProc = spawn('tail', ['-f', '-n', '50', ...logFiles], {
    stdio: ['ignore', 'inherit', 'inherit'],
  });

  runningProcesses.push(tailProc);

  await new Promise<void>((resolve) => {
    tailProc.on('exit', () => resolve());
  });
}

async function rotateLogs(services: ServiceConfig[]): Promise<void> {
  logHeader('Rotating Logs');

  for (const svc of services) {
    if (existsSync(svc.logFile)) {
      const size = formatSize(getLogSize(svc.logFile));
      rotateLog(svc.logFile);
      logOk(`${svc.name}.log rotated (was ${size})`);
    } else {
      logInfo(`${svc.name}.log (no log file)`);
    }
  }
  log('');
}

// ==============================================================================
// CLI
// ==============================================================================

interface ParsedArgs {
  command: string;
  services: string[];
  foreground: boolean;
  detailed: boolean;
  rotate: boolean;
  verbose: boolean;
}

function parseArgs(): ParsedArgs {
  const args = process.argv.slice(2);
  const result: ParsedArgs = {
    command: args[0] || 'status',
    services: [],
    foreground: false,
    detailed: false,
    rotate: false,
    verbose: false,
  };

  const SERVICES = getServices();
  const allServices = Object.keys(SERVICES);

  for (let i = 1; i < args.length; i++) {
    const arg = args[i] ?? '';
    if (arg === '--all') {
      result.services = allServices;
    } else if (arg === '--fg' || arg === '--foreground') {
      result.foreground = true;
    } else if (arg === '--detail' || arg === '--detailed') {
      result.detailed = true;
    } else if (arg === '--rotate') {
      result.rotate = true;
    } else if (arg === '--verbose' || arg === '-v') {
      result.verbose = true;
    } else if (arg && allServices.includes(arg)) {
      result.services.push(arg);
    }
  }

  if (result.services.length === 0) {
    result.services = allServices;
  }

  return result;
}

async function main(): Promise<void> {
  loadEnv();
  ensureDirs();
  setupSignalHandlers();

  const SERVICES = getServices();
  const args = parseArgs();
  const services = args.services
    .map((name) => SERVICES[name])
    .filter((s): s is ServiceConfig => s !== undefined);

  switch (args.command) {
    case 'start':
      logHeader('Starting Services');
      for (const svc of services) {
        await startService(svc, { foreground: args.foreground, verbose: args.verbose });
      }
      if (args.foreground && runningProcesses.length > 0) {
        await Promise.all(
          runningProcesses.map(
            (proc) => new Promise<void>((resolve) => proc.on('exit', () => resolve()))
          )
        );
      }
      break;

    case 'stop':
      logHeader('Stopping Services');
      for (const svc of [...services].reverse()) {
        await stopService(svc);
      }
      break;

    case 'status':
      await showStatus(services, args.detailed);
      break;

    case 'tail':
      await tailLogs(services);
      break;

    case 'logs':
      if (args.rotate) {
        await rotateLogs(services);
      } else {
        logHeader('Log Files');
        for (const svc of services) {
          const size = existsSync(svc.logFile)
            ? formatSize(getLogSize(svc.logFile))
            : '(not found)';
          log(`  ${svc.name.padEnd(12)} ${svc.logFile} [${size}]`);
        }
        log('');
      }
      break;

    default:
      logErr(`Unknown command: ${args.command}`);
      log('');
      log('Commands: start, stop, status, tail, logs');
      log('Services: dev, preview, --all');
      log('Options:  --fg (foreground), --detail, --rotate, --verbose');
      process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
