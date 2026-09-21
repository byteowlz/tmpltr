import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import {
  Bold, Check, ChevronDown, Columns3, Download, FileText, Italic,
  LayoutTemplate, List, ListOrdered, Minus, Palette, PanelLeftClose,
  Redo2, Save, Settings2, SlidersHorizontal, Undo2, ZoomIn, ZoomOut,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { documentSource } from './document-source';
import { renderTypst } from './typst';

type Mode = 'content' | 'layout' | 'style';
type Design = { accent: string; font: string; density: number; margin: number };

const initial = {
  number: 'AN-2026-041',
  date: '18 March 2026',
  title: 'AI-assisted engineering workflows',
  client: 'Nordwerk Systems GmbH',
  contact: 'Mara Hoffmann',
  total: '€ 24,800.00',
};

const sections = [
  ['document', 'Document', FileText],
  ['client', 'Client', Columns3],
  ['content', 'Content blocks', LayoutTemplate],
] as const;

export function App() {
  const [mode, setMode] = useState<Mode>('content');
  const [data, setData] = useState(initial);
  const [active, setActive] = useState('document');
  const [zoom, setZoom] = useState(100);
  const [saved, setSaved] = useState(true);
  const [revision, setRevision] = useState(0);
  const [panel, setPanel] = useState(false);
  const [design, setDesign] = useState<Design>({ accent: '#3ba77c', font: 'mono', density: 1, margin: 52 });

  const editor = useEditor({
    extensions: [StarterKit],
    content: '<p>Nordwerk Systems is building a reliable workflow for technical teams to collaborate with AI agents. This proposal covers discovery, implementation and enablement.</p><p>We will deliver a documented target workflow, two production-ready agent integrations, and training for the core team.</p>',
    onUpdate: () => {
      setSaved(false);
      setRevision((current) => current + 1);
    },
  });

  const setField = (key: keyof typeof data, value: string) => {
    setData((current) => ({ ...current, [key]: value }));
    setSaved(false);
  };
  const setStyle = <K extends keyof Design>(key: K, value: Design[K]) => {
    setDesign((current) => ({ ...current, [key]: value }));
    setSaved(false);
  };

  const payload = useMemo(() => ({
    meta: { template: 'byteowlz-angebot', version: '1.0.0' },
    quote: data,
    blocks: { intro: { format: 'html', content: editor?.getHTML() ?? '' } },
    design,
  }), [data, design, editor, revision]);

  const download = () => {
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'angebot.json';
    link.click();
    URL.revokeObjectURL(link.href);
  };

  return <main className="app-shell">
    <header className="topbar">
      <div className="brand"><span className="owl-mark">◒</span><strong>byteowlz</strong><span className="slash">/</span><span>tmpltr</span></div>
      <div className="document-name"><FileText size={14}/><span>angebot-nordwerk.toml</span><span className={saved ? 'saved' : 'unsaved'}>{saved ? 'saved' : 'edited'}</span></div>
      <div className="top-actions">
        <button className="icon-button" aria-label="Settings"><Settings2 size={16}/></button>
        <button className="button secondary" onClick={download}><Download size={15}/> Export</button>
        <button className="button primary" onClick={() => setSaved(true)}><Save size={15}/> Save</button>
      </div>
    </header>

    <div className="modebar">
      <div className="mode-switch" aria-label="Editing mode">
        <button className={mode === 'content' ? 'active' : ''} onClick={() => { setMode('content'); setPanel(false); }}><FileText size={15}/> Content</button>
        <button className={mode === 'layout' ? 'active' : ''} onClick={() => { setMode('layout'); setPanel(true); }}><LayoutTemplate size={15}/> Layout</button>
        <button className={mode === 'style' ? 'active' : ''} onClick={() => { setMode('style'); setPanel(true); }}><Palette size={15}/> Style</button>
      </div>
      <div className="scope"><span className="scope-dot"/> Editing <strong>{mode === 'content' ? 'document content' : mode === 'layout' ? 'document layout' : 'document style'}</strong><span className="scope-path">changes affect only this document</span></div>
      <button className="icon-button collapse" onClick={() => setPanel(!panel)} title="Toggle inspector"><PanelLeftClose size={16}/></button>
    </div>

    <div className={`workspace ${panel ? '' : 'panel-hidden'}`}>
      {panel && <aside className="inspector">
        {mode === 'content' ? <>
          <div className="panel-heading"><div><span className="eyebrow">Document data</span><h1>Proposal</h1></div><button className="icon-button"><SlidersHorizontal size={15}/></button></div>
          <nav className="section-nav">{sections.map(([id, label, Icon]) => <button key={id} className={active === id ? 'active' : ''} onClick={() => setActive(id)}><Icon size={15}/><span>{label}</span><span className="section-state"><Check size={12}/></span></button>)}</nav>
          <div className="form-area">
            {active === 'document' && <>
              <SectionTitle index="01" title="Document" />
              <Field label="Proposal title" value={data.title} onChange={(v) => setField('title', v)} />
              <div className="field-row"><Field label="Number" value={data.number} onChange={(v) => setField('number', v)} /><Field label="Date" value={data.date} onChange={(v) => setField('date', v)} /></div>
              <Field label="Total" value={data.total} onChange={(v) => setField('total', v)} />
            </>}
            {active === 'client' && <>
              <SectionTitle index="02" title="Client" />
              <Field label="Company" value={data.client} onChange={(v) => setField('client', v)} />
              <Field label="Contact person" value={data.contact} onChange={(v) => setField('contact', v)} />
            </>}
            {active === 'content' && <>
              <SectionTitle index="03" title="Content blocks" />
              <div className="rich-editor">
                <div className="editor-toolbar">
                  <Tool active={editor?.isActive('bold')} onClick={() => editor?.chain().focus().toggleBold().run()}><Bold size={14}/></Tool>
                  <Tool active={editor?.isActive('italic')} onClick={() => editor?.chain().focus().toggleItalic().run()}><Italic size={14}/></Tool>
                  <Tool active={editor?.isActive('bulletList')} onClick={() => editor?.chain().focus().toggleBulletList().run()}><List size={14}/></Tool>
                  <Tool active={editor?.isActive('orderedList')} onClick={() => editor?.chain().focus().toggleOrderedList().run()}><ListOrdered size={14}/></Tool>
                  <span className="tool-spacer"/><Tool onClick={() => editor?.chain().focus().undo().run()}><Undo2 size={14}/></Tool><Tool onClick={() => editor?.chain().focus().redo().run()}><Redo2 size={14}/></Tool>
                </div>
                <EditorContent editor={editor}/>
              </div>
            </>}
          </div>
        </> : <DesignPanel mode={mode} design={design} setStyle={setStyle}/>} 
      </aside>}

      <section className="canvas">
        <div className="canvas-toolbar"><span>{mode === 'content' ? 'EDIT THE PAGE' : 'LIVE PREVIEW'}</span><span className="compile-state"><Check size={12}/> {mode === 'content' ? 'changes compile as you type' : 'compiled 0.4s ago'}</span><div className="zoom"><button onClick={() => setZoom(Math.max(50, zoom - 8))}><ZoomOut size={14}/></button><span>{zoom}%</span><button onClick={() => setZoom(Math.min(130, zoom + 8))}><ZoomIn size={14}/></button></div></div>
        <div className="paper-stage">
          <TypstPage
            mode={mode}
            zoom={zoom}
            data={data}
            design={design}
            editor={editor}
            onFieldChange={setField}
          />
        </div>
      </section>
    </div>
  </main>;
}

function TypstPage({ mode, zoom, data, design, editor, onFieldChange }: {
  mode: Mode;
  zoom: number;
  data: typeof initial;
  design: Design;
  editor: ReturnType<typeof useEditor>;
  onFieldChange: (key: keyof typeof initial, value: string) => void;
}) {
  const [svg, setSvg] = useState('');
  const [compileState, setCompileState] = useState<'loading' | 'ready' | 'error'>('loading');
  const generation = useRef(0);
  const intro = editor?.getText() ?? '';

  useEffect(() => {
    const current = ++generation.current;
    setCompileState('loading');
    const timeout = window.setTimeout(() => {
      renderTypst(documentSource({ ...data, intro }, design))
        .then((output) => {
          if (current !== generation.current) return;
          setSvg(output);
          setCompileState('ready');
        })
        .catch(() => {
          if (current === generation.current) setCompileState('error');
        });
    }, svg ? 140 : 0);
    return () => window.clearTimeout(timeout);
  }, [data, design, intro]);

  const editable = mode === 'content';
  const marginPercent = (design.margin * 0.36 / 210) * 100;
  const common = { left: `${marginPercent}%`, width: `${100 - marginPercent * 2}%` };

  return <article className={`typst-page ${editable ? 'is-editing' : ''}`} style={{ transform: `scale(${zoom / 100})`, '--accent': design.accent } as React.CSSProperties}>
    <div className="typst-render" dangerouslySetInnerHTML={{ __html: svg }}/>
    {!svg && <div className="typst-loading">Loading Typst compiler…<span>~28 MB on first load</span></div>}
    <div className={`compiler-pill ${compileState}`}><span/>{compileState === 'loading' ? 'compiling' : compileState === 'ready' ? 'typst live' : 'compile error'}</div>
    <div className="edit-region number-region" style={{ right: `${marginPercent}%` }}><EditableText enabled={editable} label="Proposal number" value={data.number} onChange={(value) => onFieldChange('number', value)}/></div>
    <div className="edit-region date-region" style={common}><EditableText enabled={editable} label="Date" value={data.date.toUpperCase()} onChange={(value) => onFieldChange('date', value)}/></div>
    <div className="edit-region title-region" style={common}><EditableText enabled={editable} label="Proposal title" value={data.title} multiline onChange={(value) => onFieldChange('title', value)}/></div>
    <div className="edit-region client-region" style={{ left: `${marginPercent}%`, width: '48%' }}><EditableText enabled={editable} label="Client company" value={data.client} onChange={(value) => onFieldChange('client', value)}/><small><EditableText enabled={editable} label="Contact person" value={data.contact} onChange={(value) => onFieldChange('contact', value)}/></small></div>
    <div className="edit-region total-region" style={{ right: `${marginPercent}%`, width: '27%' }}><EditableText enabled={editable} label="Total investment" value={data.total} onChange={(value) => onFieldChange('total', value)}/></div>
    {editable && <div className="edit-region intro-region" style={common}>
      <div className="page-editor-tools"><Tool active={editor?.isActive('bold')} onClick={() => editor?.chain().focus().toggleBold().run()}><Bold size={12}/></Tool><Tool active={editor?.isActive('italic')} onClick={() => editor?.chain().focus().toggleItalic().run()}><Italic size={12}/></Tool><Tool active={editor?.isActive('bulletList')} onClick={() => editor?.chain().focus().toggleBulletList().run()}><List size={12}/></Tool></div>
      <EditorContent editor={editor}/>
    </div>}
  </article>;
}

function EditableText({ enabled, label, value, multiline = false, onChange }: { enabled: boolean; label: string; value: string; multiline?: boolean; onChange: (value: string) => void }) {
  if (!enabled) return <>{value}</>;
  return <span
    className="direct-edit"
    contentEditable
    suppressContentEditableWarning
    data-field={label}
    role="textbox"
    aria-label={label}
    aria-multiline={multiline}
    onKeyDown={(event) => {
      if (!multiline && event.key === 'Enter') {
        event.preventDefault();
        event.currentTarget.blur();
      }
      if (event.key === 'Escape') event.currentTarget.blur();
    }}
    onInput={(event) => onChange(event.currentTarget.textContent ?? '')}
  >{value}</span>;
}

function SectionTitle({ index, title }: { index: string; title: string }) { return <div className="section-title"><span>{index}</span><h2>{title}</h2><Minus size={18}/></div>; }
function Field({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) { return <label className="field"><span>{label}</span><input value={value} onChange={(e) => onChange(e.target.value)}/></label>; }
function Tool({ children, active, onClick }: { children: React.ReactNode; active?: boolean; onClick?: () => void }) { return <button className={active ? 'active' : ''} onClick={onClick}>{children}</button>; }

function DesignPanel({ mode, design, setStyle }: { mode: Exclude<Mode, 'content'>; design: Design; setStyle: <K extends keyof Design>(key: K, value: Design[K]) => void }) {
  const colors = ['#3ba77c', '#5b8fc9', '#c98a5a', '#b94a48', '#a78bd0'];
  const layout = mode === 'layout';
  return <>
    <div className="panel-heading"><div><span className="eyebrow">Current document</span><h1>{layout ? 'Layout' : 'Style'}</h1></div>{layout ? <LayoutTemplate size={17}/> : <Palette size={17}/>}</div>
    <div className="design-area">
      <SectionTitle index="01" title={layout ? 'Page geometry' : 'Visual language'} />
      {layout ? <>
        <div className="range-control"><div><span>Page margin</span><b>{design.margin} px</b></div><input type="range" min="36" max="76" value={design.margin} onChange={(e) => setStyle('margin', Number(e.target.value))}/></div>
        <div className="range-control"><div><span>Vertical rhythm</span><b>{design.density.toFixed(1)}×</b></div><input type="range" min="0.8" max="1.3" step="0.1" value={design.density} onChange={(e) => setStyle('density', Number(e.target.value))}/></div>
      </> : <>
        <label className="field"><span>Typeface</span><div className="select-wrap"><select value={design.font} onChange={(e) => setStyle('font', e.target.value)}><option value="mono">Technical Mono</option><option value="editorial">Editorial Serif</option><option value="clean">Clean Sans</option></select><ChevronDown size={14}/></div></label>
        <div className="control-group"><span>Accent color</span><div className="swatches">{colors.map((color) => <button key={color} aria-label={color} className={design.accent === color ? 'active' : ''} style={{ background: color }} onClick={() => setStyle('accent', color)}>{design.accent === color && <Check size={13}/>}</button>)}</div></div>
      </>}
      <div className="impact-note safe"><strong>Local experiment</strong><p>Changes affect only this document. Nothing is written back to the shared template or Brand.</p></div>
    </div>
  </>;
}
