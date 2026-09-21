import { $typst } from '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs';
import compilerWasm from '@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm?url';
import rendererWasm from '@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm?url';

export type TypstRequest = { id: number; source: string };
export type TypstResponse = { id: number; ok: true; svg: string } | { id: number; ok: false; error: string };

$typst.setCompilerInitOptions({ getModule: () => compilerWasm });
$typst.setRendererInitOptions({ getModule: () => rendererWasm });

let queue: Promise<unknown> = Promise.resolve();
self.onmessage = (event: MessageEvent<TypstRequest>) => {
  const request = event.data;
  const run = queue.then(async () => {
    try {
      const svg = await $typst.svg({ mainContent: request.source });
      self.postMessage({ id: request.id, ok: true, svg } satisfies TypstResponse);
    } catch (error) {
      self.postMessage({ id: request.id, ok: false, error: String(error) } satisfies TypstResponse);
    }
  });
  queue = run.catch(() => undefined);
};
