let callbackCounter = 0;
function getUniqueCallbackName(prefix) {
  return `${prefix}_callback_${Date.now()}_${callbackCounter++}`;
}
export function exec(command, options) {
  if (typeof options === "undefined") options = {};
  return new Promise((resolve, reject) => {
    const callbackFuncName = getUniqueCallbackName("exec");
    window[callbackFuncName] = (errno, stdout, stderr) => {
      resolve({ errno, stdout, stderr });
      delete window[callbackFuncName];
    };
    try {
      if (typeof ksu === "undefined" || typeof ksu.exec !== "function") {
        throw new Error("KernelSU WebUI API unavailable. Open this page from KernelSU or a compatible module manager.");
      }
      ksu.exec(command, JSON.stringify(options), callbackFuncName);
    } catch (error) {
      delete window[callbackFuncName];
      reject(error);
    }
  });
}
export function toast(message) {
  if (typeof ksu !== "undefined" && typeof ksu.toast === "function") ksu.toast(message);
}
export function fullScreen(isFullScreen) {
  if (typeof ksu !== "undefined" && typeof ksu.fullScreen === "function") ksu.fullScreen(isFullScreen);
}
