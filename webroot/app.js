import { exec, toast } from './kernelsu.js';

const SCRIPT = '/data/adb/modules/usb_role_switch/bin/usb-role.sh';
const $ = (id) => document.getElementById(id);
const buttons = [
  'btn-power-source', 'btn-power-sink', 'btn-power-toggle',
  'btn-data-host', 'btn-data-device', 'btn-data-toggle',
  'btn-source-host', 'btn-sink-device', 'btn-pair-toggle', 'btn-refresh',
  'btn-log', 'btn-clear-log', 'btn-copy-status', 'btn-copy-output'
];

function setBusy(busy) {
  for (const id of buttons) {
    const el = $(id);
    if (el) el.disabled = busy;
  }
}

function activeFromLine(line) {
  const match = line.match(/\[([^\]]+)\]/);
  return match ? match[1] : 'unknown';
}

function inferMode(statusText) {
  const powerLine = (statusText.match(/^power_role:\s*(.*)$/m) || [])[1] || '';
  const dataLine = (statusText.match(/^data_role:\s*(.*)$/m) || [])[1] || '';
  return `${activeFromLine(powerLine)} / ${activeFromLine(dataLine)}`;
}

function updatePill(text) {
  const pill = $('pill');
  pill.textContent = text;
  pill.className = 'pill';
  if (text.includes('source')) pill.classList.add('source');
  if (text.includes('sink')) pill.classList.add('sink');
}

async function run(command, target = 'output') {
  setBusy(true);
  try {
    const { errno, stdout, stderr } = await exec(command);
    const out = `${stdout || ''}${stderr ? '\n[stderr]\n' + stderr : ''}`.trim();
    $(target).textContent = out || `<empty, errno=${errno}>`;
    if (target === 'status') updatePill(inferMode(out));
    toast(errno === 0 ? 'Done' : `Exit ${errno}`);
    return { errno, out };
  } catch (e) {
    const msg = String(e && e.message ? e.message : e);
    $(target).textContent = msg;
    toast('Error');
    return { errno: -1, out: msg };
  } finally {
    setBusy(false);
  }
}

async function refreshStatus() {
  await run(`${SCRIPT} status`, 'status');
}

async function refreshLog() {
  await run(`${SCRIPT} log`, 'log');
}

async function runRole(command) {
  await run(`${SCRIPT} ${command}`, 'output');
  await refreshStatus();
  await refreshLog();
}

function bind(id, fn) {
  $(id).addEventListener('click', fn);
}

bind('btn-power-source', () => runRole('power-source'));
bind('btn-power-sink', () => runRole('power-sink'));
bind('btn-power-toggle', () => runRole('power-toggle'));
bind('btn-data-host', () => runRole('data-host'));
bind('btn-data-device', () => runRole('data-device'));
bind('btn-data-toggle', () => runRole('data-toggle'));
bind('btn-source-host', () => runRole('source-host'));
bind('btn-sink-device', () => runRole('sink-device'));
bind('btn-pair-toggle', () => runRole('pair-toggle'));
bind('btn-refresh', refreshStatus);
bind('btn-log', refreshLog);
bind('btn-clear-log', async () => {
  await run(`${SCRIPT} clear-log`, 'output');
  await refreshLog();
});
bind('btn-copy-status', async () => copyText($('status').textContent));
bind('btn-copy-output', async () => copyText($('output').textContent));

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    toast('Copied');
  } catch (_) {
    toast('Copy failed');
  }
}

refreshStatus();
refreshLog();
