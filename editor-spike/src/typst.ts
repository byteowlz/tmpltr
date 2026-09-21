import type { TypstRequest, TypstResponse } from './typst.worker';

let worker: Worker | undefined;
let nextId = 1;
const pending = new Map<number, { resolve: (svg: string) => void; reject: (error: unknown) => void }>();

function getWorker() {
  if (worker) return worker;
  worker = new Worker(new URL('./typst.worker.ts', import.meta.url), { type: 'module' });
  worker.onmessage = (event: MessageEvent<TypstResponse>) => {
    const response = event.data;
    const request = pending.get(response.id);
    if (!request) return;
    pending.delete(response.id);
    if (response.ok) request.resolve(response.svg);
    else request.reject(new Error(response.error));
  };
  return worker;
}

export function renderTypst(source: string): Promise<string> {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    getWorker().postMessage({ id, source } satisfies TypstRequest);
  });
}
