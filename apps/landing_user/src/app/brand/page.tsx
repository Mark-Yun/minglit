'use client';

import React, { useState, useEffect } from 'react';
import { Sun, Moon, Heart, Briefcase, FileImage, FileCode2 } from 'lucide-react';

const brandColors = {
  primary: '#9900ff',
  secondary: '#ff9900',
  accent: '#21fffe',
  hotpink: '#ff0080',
  highlight: '#d185ff',
};

const EXPORT_SIZE = 1600;
// viewBox: -10 -10 140 140 → 120 content + 10 padding each side ≈ 8%
const VB_MIN = -10;
const VB_SIZE = 140;

const BUBBLE_PATH =
  'M22,25 C22,13 35,11 60,12 C85,13 100,13 100,25 C100,38 102,58 100,68 C98,78 85,78 60,78 C52,78 48,88 42,92 C37,88 40,78 28,78 C22,78 22,68 22,45 Z';
const SPARK_PATH =
  'M108 8C109 18 113 22 120 23C113 24 109 25 108 38C107 28 103 24 95 23C103 19 107 15 108 8Z';

let fontBase64Cache: string | null = null;

async function loadFontBase64(): Promise<string | null> {
  if (fontBase64Cache) return fontBase64Cache;
  try {
    const cssRes = await fetch(
      'https://fonts.googleapis.com/css2?family=Dancing+Script:wght@700&display=swap',
    );
    const cssText = await cssRes.text();
    const woff2Match = cssText.match(/url\((https:\/\/fonts\.gstatic\.com[^)]+\.woff2)\)/);
    if (!woff2Match) return null;
    const fontRes = await fetch(woff2Match[1]);
    const buf = await fontRes.arrayBuffer();
    const bytes = new Uint8Array(buf);
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    fontBase64Cache = btoa(binary);
    return fontBase64Cache;
  } catch {
    return null;
  }
}

function svgFontStyle(b64: string | null): string {
  if (b64) {
    return `<style>@font-face{font-family:'Dancing Script';font-weight:700;src:url(data:font/woff2;base64,${b64}) format('woff2');}</style>`;
  }
  return `<style>@import url('https://fonts.googleapis.com/css2?family=Dancing+Script:wght@700&amp;display=swap');</style>`;
}

const VB = `viewBox="${VB_MIN} ${VB_MIN} ${VB_SIZE} ${VB_SIZE}" width="${EXPORT_SIZE}" height="${EXPORT_SIZE}"`;
const R = `x="${VB_MIN}" y="${VB_MIN}" width="${VB_SIZE}" height="${VB_SIZE}"`;

function buildPartnerFullSvg(fs: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}>${fs}
<defs>
<radialGradient id="pf1" cx="20%" cy="20%" r="60%"><stop offset="0%" stop-color="#21fffe" stop-opacity="0.4"/><stop offset="100%" stop-color="#21fffe" stop-opacity="0"/></radialGradient>
<radialGradient id="pf2" cx="80%" cy="30%" r="50%"><stop offset="0%" stop-color="white" stop-opacity="0.2"/><stop offset="100%" stop-color="white" stop-opacity="0"/></radialGradient>
<radialGradient id="pf3" cx="50%" cy="85%" r="60%"><stop offset="0%" stop-color="#ff0080" stop-opacity="0.35"/><stop offset="100%" stop-color="#ff0080" stop-opacity="0"/></radialGradient>
</defs>
<rect ${R} fill="${brandColors.primary}"/><rect ${R} fill="url(#pf1)"/><rect ${R} fill="url(#pf2)"/><rect ${R} fill="url(#pf3)"/>
<g transform="translate(-12,0) scale(1.2)"><path d="${BUBBLE_PATH}" fill="white"/><text x="60" y="52" font-family="Dancing Script,cursive" font-size="52" font-weight="700" text-anchor="middle" fill="${brandColors.primary}">m</text></g>
<path d="${SPARK_PATH}" fill="${brandColors.secondary}"/></svg>`;
}

function buildPartnerObjSvg(fs: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}>${fs}
<g transform="translate(-12,0) scale(1.2)"><path d="${BUBBLE_PATH}" fill="white"/><text x="60" y="52" font-family="Dancing Script,cursive" font-size="52" font-weight="700" text-anchor="middle" fill="${brandColors.primary}">m</text></g>
<path d="${SPARK_PATH}" fill="${brandColors.secondary}"/></svg>`;
}

function buildPartnerBgSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}>
<defs>
<radialGradient id="pb1" cx="20%" cy="20%" r="60%"><stop offset="0%" stop-color="#21fffe" stop-opacity="0.4"/><stop offset="100%" stop-color="#21fffe" stop-opacity="0"/></radialGradient>
<radialGradient id="pb2" cx="80%" cy="30%" r="50%"><stop offset="0%" stop-color="white" stop-opacity="0.2"/><stop offset="100%" stop-color="white" stop-opacity="0"/></radialGradient>
<radialGradient id="pb3" cx="50%" cy="85%" r="60%"><stop offset="0%" stop-color="#ff0080" stop-opacity="0.35"/><stop offset="100%" stop-color="#ff0080" stop-opacity="0"/></radialGradient>
</defs>
<rect ${R} fill="${brandColors.primary}"/><rect ${R} fill="url(#pb1)"/><rect ${R} fill="url(#pb2)"/><rect ${R} fill="url(#pb3)"/></svg>`;
}

function buildUserFullSvg(fs: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}>${fs}
<defs>
<clipPath id="ufc"><path d="${BUBBLE_PATH}" transform="translate(-12,0) scale(1.2)"/></clipPath>
<radialGradient id="uf1" cx="25%" cy="25%" r="55%"><stop offset="0%" stop-color="#21fffe" stop-opacity="0.5"/><stop offset="100%" stop-color="#21fffe" stop-opacity="0"/></radialGradient>
<radialGradient id="uf2" cx="75%" cy="30%" r="50%"><stop offset="0%" stop-color="white" stop-opacity="0.25"/><stop offset="100%" stop-color="white" stop-opacity="0"/></radialGradient>
<radialGradient id="uf3" cx="55%" cy="85%" r="60%"><stop offset="0%" stop-color="#ff0080" stop-opacity="0.4"/><stop offset="100%" stop-color="#ff0080" stop-opacity="0"/></radialGradient>
<linearGradient id="uf4" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="white" stop-opacity="0.3"/><stop offset="50%" stop-color="white" stop-opacity="0"/></linearGradient>
</defs>
<rect ${R} fill="white"/>
<g transform="translate(-12,0) scale(1.2)"><path d="${BUBBLE_PATH}" fill="${brandColors.primary}"/></g>
<g clip-path="url(#ufc)"><rect ${R} fill="url(#uf1)"/><rect ${R} fill="url(#uf2)"/><rect ${R} fill="url(#uf3)"/><rect ${R} fill="url(#uf4)"/></g>
<g transform="translate(-12,0) scale(1.2)"><text x="60" y="52" font-family="Dancing Script,cursive" font-size="52" font-weight="700" text-anchor="middle" fill="white">m</text></g>
<path d="${SPARK_PATH}" fill="${brandColors.secondary}"/></svg>`;
}

function buildUserObjSvg(fs: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}>${fs}
<defs>
<clipPath id="uoc"><path d="${BUBBLE_PATH}" transform="translate(-12,0) scale(1.2)"/></clipPath>
<radialGradient id="uo1" cx="25%" cy="25%" r="55%"><stop offset="0%" stop-color="#21fffe" stop-opacity="0.5"/><stop offset="100%" stop-color="#21fffe" stop-opacity="0"/></radialGradient>
<radialGradient id="uo2" cx="75%" cy="30%" r="50%"><stop offset="0%" stop-color="white" stop-opacity="0.25"/><stop offset="100%" stop-color="white" stop-opacity="0"/></radialGradient>
<radialGradient id="uo3" cx="55%" cy="85%" r="60%"><stop offset="0%" stop-color="#ff0080" stop-opacity="0.4"/><stop offset="100%" stop-color="#ff0080" stop-opacity="0"/></radialGradient>
<linearGradient id="uo4" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="white" stop-opacity="0.3"/><stop offset="50%" stop-color="white" stop-opacity="0"/></linearGradient>
</defs>
<g transform="translate(-12,0) scale(1.2)"><path d="${BUBBLE_PATH}" fill="${brandColors.primary}"/></g>
<g clip-path="url(#uoc)"><rect ${R} fill="url(#uo1)"/><rect ${R} fill="url(#uo2)"/><rect ${R} fill="url(#uo3)"/><rect ${R} fill="url(#uo4)"/></g>
<g transform="translate(-12,0) scale(1.2)"><text x="60" y="52" font-family="Dancing Script,cursive" font-size="52" font-weight="700" text-anchor="middle" fill="white">m</text></g>
<path d="${SPARK_PATH}" fill="${brandColors.secondary}"/></svg>`;
}

function buildUserBgSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" ${VB}><rect ${R} fill="white"/></svg>`;
}

function triggerDownload(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

async function dlSvg(buildFn: (fs: string) => string, name: string) {
  const b64 = await loadFontBase64();
  triggerDownload(new Blob([buildFn(svgFontStyle(b64))], { type: 'image/svg+xml;charset=utf-8' }), `${name}.svg`);
}

async function dlSvgNoFont(buildFn: () => string, name: string) {
  triggerDownload(new Blob([buildFn()], { type: 'image/svg+xml;charset=utf-8' }), `${name}.svg`);
}

function createExportCanvas(): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement('canvas');
  c.width = EXPORT_SIZE;
  c.height = EXPORT_SIZE;
  const ctx = c.getContext('2d')!;
  const scale = EXPORT_SIZE / VB_SIZE;
  ctx.scale(scale, scale);
  ctx.translate(-VB_MIN, -VB_MIN);
  return [c, ctx];
}

function getBubblePath2D(): Path2D {
  const raw = new Path2D(BUBBLE_PATH);
  const p = new Path2D();
  p.addPath(raw, new DOMMatrix().translate(-12, 0).scale(1.2, 1.2));
  return p;
}

function drawVibrantBg(ctx: CanvasRenderingContext2D) {
  ctx.fillStyle = brandColors.primary;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g1 = ctx.createRadialGradient(18, 18, 0, 18, 18, 84);
  g1.addColorStop(0, 'rgba(33,255,254,0.4)');
  g1.addColorStop(1, 'rgba(33,255,254,0)');
  ctx.fillStyle = g1;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g2 = ctx.createRadialGradient(102, 32, 0, 102, 32, 70);
  g2.addColorStop(0, 'rgba(255,255,255,0.2)');
  g2.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g2;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g3 = ctx.createRadialGradient(60, 109, 0, 60, 109, 84);
  g3.addColorStop(0, 'rgba(255,0,128,0.35)');
  g3.addColorStop(1, 'rgba(255,0,128,0)');
  ctx.fillStyle = g3;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);
}

function drawUserGradients(ctx: CanvasRenderingContext2D, clip: Path2D) {
  ctx.save();
  ctx.clip(clip);

  const g1 = ctx.createRadialGradient(25, 25, 0, 25, 25, 77);
  g1.addColorStop(0, 'rgba(33,255,254,0.5)');
  g1.addColorStop(1, 'rgba(33,255,254,0)');
  ctx.fillStyle = g1;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g2 = ctx.createRadialGradient(95, 32, 0, 95, 32, 70);
  g2.addColorStop(0, 'rgba(255,255,255,0.25)');
  g2.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g2;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g3 = ctx.createRadialGradient(67, 109, 0, 67, 109, 84);
  g3.addColorStop(0, 'rgba(255,0,128,0.4)');
  g3.addColorStop(1, 'rgba(255,0,128,0)');
  ctx.fillStyle = g3;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  const g4 = ctx.createLinearGradient(0, VB_MIN, 0, VB_MIN + VB_SIZE);
  g4.addColorStop(0, 'rgba(255,255,255,0.3)');
  g4.addColorStop(0.5, 'rgba(255,255,255,0)');
  ctx.fillStyle = g4;
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);

  ctx.restore();
}

function drawM(ctx: CanvasRenderingContext2D, fill: string) {
  ctx.save();
  ctx.translate(-12, 0);
  ctx.scale(1.2, 1.2);
  ctx.font = "bold 52px 'Dancing Script'";
  ctx.textAlign = 'center';
  ctx.textBaseline = 'alphabetic';
  ctx.fillStyle = fill;
  ctx.fillText('m', 60, 52);
  ctx.restore();
}

function drawSpark(ctx: CanvasRenderingContext2D) {
  ctx.fillStyle = brandColors.secondary;
  ctx.fill(new Path2D(SPARK_PATH));
}

async function dlPng(render: (ctx: CanvasRenderingContext2D) => void, name: string) {
  await document.fonts.ready;
  if (!document.fonts.check("bold 52px 'Dancing Script'")) {
    await document.fonts.load("bold 52px 'Dancing Script'");
  }
  const [canvas, ctx] = createExportCanvas();
  render(ctx);
  return new Promise<void>((resolve) => {
    canvas.toBlob((blob) => {
      if (blob) triggerDownload(blob, `${name}.png`);
      resolve();
    }, 'image/png');
  });
}

function renderPartnerFull(ctx: CanvasRenderingContext2D) {
  const bubble = getBubblePath2D();
  drawVibrantBg(ctx);
  ctx.fillStyle = 'white';
  ctx.fill(bubble);
  drawM(ctx, brandColors.primary);
  drawSpark(ctx);
}

function renderPartnerObj(ctx: CanvasRenderingContext2D) {
  const bubble = getBubblePath2D();
  ctx.fillStyle = 'white';
  ctx.fill(bubble);
  drawM(ctx, brandColors.primary);
  drawSpark(ctx);
}

function renderPartnerBg(ctx: CanvasRenderingContext2D) {
  drawVibrantBg(ctx);
}

function renderUserFull(ctx: CanvasRenderingContext2D) {
  const bubble = getBubblePath2D();
  ctx.fillStyle = 'white';
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);
  ctx.fillStyle = brandColors.primary;
  ctx.fill(bubble);
  drawUserGradients(ctx, bubble);
  drawM(ctx, 'white');
  drawSpark(ctx);
}

function renderUserObj(ctx: CanvasRenderingContext2D) {
  const bubble = getBubblePath2D();
  ctx.fillStyle = brandColors.primary;
  ctx.fill(bubble);
  drawUserGradients(ctx, bubble);
  drawM(ctx, 'white');
  drawSpark(ctx);
}

function renderUserBg(ctx: CanvasRenderingContext2D) {
  ctx.fillStyle = 'white';
  ctx.fillRect(VB_MIN, VB_MIN, VB_SIZE, VB_SIZE);
}

interface MingleSymbolProps {
  fillM: string;
  fillBubble?: string;
  fillSpark: string;
  useVibrantSystem?: boolean;
  showShadow?: boolean;
  uniqueId?: string;
  className?: string;
}

const MingleSymbol = ({
  fillM,
  fillBubble = 'white',
  fillSpark,
  useVibrantSystem = false,
  showShadow = false,
  uniqueId = 'mingle',
  className = '',
}: MingleSymbolProps) => (
  <svg viewBox="0 0 120 120" className={className} xmlns="http://www.w3.org/2000/svg">
    <defs>
      {showShadow && (
        <filter id={`shadow-${uniqueId}`} x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="12" stdDeviation="25" floodColor="#000" floodOpacity="0.12" />
        </filter>
      )}
      {useVibrantSystem && (
        <>
          <clipPath id={`bubble-clip-${uniqueId}`}>
            <path d={BUBBLE_PATH} />
          </clipPath>
          <radialGradient id={`grad1-${uniqueId}`} cx="25%" cy="25%" r="55%">
            <stop offset="0%" stopColor="#21fffe" stopOpacity="0.5" />
            <stop offset="100%" stopColor="#21fffe" stopOpacity="0" />
          </radialGradient>
          <radialGradient id={`grad2-${uniqueId}`} cx="75%" cy="30%" r="50%">
            <stop offset="0%" stopColor="white" stopOpacity="0.25" />
            <stop offset="100%" stopColor="white" stopOpacity="0" />
          </radialGradient>
          <radialGradient id={`grad3-${uniqueId}`} cx="55%" cy="85%" r="60%">
            <stop offset="0%" stopColor="#ff0080" stopOpacity="0.4" />
            <stop offset="100%" stopColor="#ff0080" stopOpacity="0" />
          </radialGradient>
          <linearGradient id={`grad4-${uniqueId}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="white" stopOpacity="0.3" />
            <stop offset="50%" stopColor="white" stopOpacity="0" />
          </linearGradient>
        </>
      )}
    </defs>

    <g transform="translate(-12, 0) scale(1.2)" filter={showShadow ? `url(#shadow-${uniqueId})` : undefined}>
      <path
        d={BUBBLE_PATH}
        fill={useVibrantSystem ? brandColors.primary : fillBubble}
      />
      {useVibrantSystem && (
        <g clipPath={`url(#bubble-clip-${uniqueId})`}>
          <rect x="0" y="0" width="120" height="120" fill={`url(#grad1-${uniqueId})`} />
          <rect x="0" y="0" width="120" height="120" fill={`url(#grad2-${uniqueId})`} />
          <rect x="0" y="0" width="120" height="120" fill={`url(#grad3-${uniqueId})`} />
          <rect x="0" y="0" width="120" height="120" fill={`url(#grad4-${uniqueId})`} />
        </g>
      )}
      <text
        x="60"
        y="52"
        fontFamily="Dancing Script, cursive"
        fontSize="52px"
        fontWeight="700"
        textAnchor="middle"
        fill={fillM}
      >
        m
      </text>
    </g>
    <path d={SPARK_PATH} fill={fillSpark} />
  </svg>
);

interface DownloadGroupProps {
  label: string;
  color: string;
  hoverColor: string;
  onSvg: () => void;
  onPng: () => void;
}

function DownloadGroup({ label, color, hoverColor, onSvg, onPng }: DownloadGroupProps) {
  return (
    <div className="flex flex-col items-center gap-1.5">
      <span className="text-[10px] font-bold uppercase tracking-wider opacity-50">{label}</span>
      <div className="flex gap-1">
        <button
          onClick={onSvg}
          className={`px-3 py-1.5 ${color} ${hoverColor} text-white rounded-l-full text-[11px] font-bold transition-all flex items-center gap-1`}
        >
          <FileCode2 size={11} /> SVG
        </button>
        <button
          onClick={onPng}
          className={`px-3 py-1.5 ${color} ${hoverColor} text-white rounded-r-full text-[11px] font-bold transition-all flex items-center gap-1`}
        >
          <FileImage size={11} /> PNG
        </button>
      </div>
    </div>
  );
}

export default function BrandPage() {
  const [isDarkMode, setIsDarkMode] = useState(false);

  useEffect(() => {
    loadFontBase64();
    document.fonts.load("bold 52px 'Dancing Script'");
  }, []);

  return (
    <div
      className={`min-h-screen flex flex-col transition-colors duration-300 ${
        isDarkMode ? 'bg-[#0a0510] text-white' : 'bg-white text-slate-900'
      }`}
    >
      <header
        className={`p-6 flex justify-between items-center border-b ${
          isDarkMode ? 'border-slate-800' : 'border-slate-100'
        }`}
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 flex items-center justify-center">
            <MingleSymbol fillM={brandColors.primary} fillBubble="white" fillSpark={brandColors.secondary} uniqueId="nav" className="w-8 h-8" />
          </div>
          <h1 className="text-2xl font-racing tracking-tight uppercase italic text-mingle-gradient">
            Mingle-it
          </h1>
        </div>
        <button
          onClick={() => setIsDarkMode(!isDarkMode)}
          className={`p-2 rounded-full transition-colors ${
            isDarkMode ? 'hover:bg-slate-800' : 'hover:bg-slate-100'
          }`}
        >
          {isDarkMode ? <Sun size={20} /> : <Moon size={20} />}
        </button>
      </header>

      <main className="flex-1 p-8 md:p-12 max-w-6xl mx-auto w-full">
        <section className="mb-20 text-center">
          <h2 className="text-6xl font-racing italic uppercase mb-4 tracking-wider">
            Refined <span className="text-mingle-gradient">Mingle</span>
          </h2>

          <div
            className={`relative aspect-square max-w-sm mx-auto rounded-[60px] flex items-center justify-center border-2 shadow-xl overflow-hidden ${
              isDarkMode
                ? 'bg-slate-800/20 border-purple-500/10'
                : 'bg-slate-50 border-slate-100'
            }`}
          >
            <div className="relative w-64 h-64">
              <div className="w-full h-full floating">
                <MingleSymbol
                  fillM={brandColors.primary}
                  fillBubble={isDarkMode ? 'rgba(255,255,255,0.05)' : 'white'}
                  fillSpark={brandColors.secondary}
                  showShadow={true}
                  uniqueId="hero"
                />
              </div>
            </div>
          </div>
        </section>

        <div className="grid md:grid-cols-2 gap-8 mb-20">
          <div
            className={`p-8 rounded-3xl border shadow-lg text-center ${
              isDarkMode
                ? 'bg-slate-800/40 border-slate-800'
                : 'bg-white border-slate-100'
            }`}
          >
            <h3 className="text-lg font-racing italic uppercase mb-8 opacity-60 flex items-center justify-center gap-2">
              <Briefcase size={20} /> Partner Edition
            </h3>
            <div className="w-36 h-36 mx-auto rounded-[45%] shadow-2xl overflow-hidden">
              <div className="w-[144px] h-[144px] vibrant-bg flex items-center justify-center p-[12px]">
                <div className="w-full h-full">
                  <MingleSymbol fillM={brandColors.primary} fillBubble="white" fillSpark={brandColors.secondary} uniqueId="partner-ui" />
                </div>
              </div>
            </div>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <DownloadGroup
                label="전체"
                color="bg-[#9900ff]"
                hoverColor="hover:bg-[#7a00cc]"
                onSvg={() => dlSvg(buildPartnerFullSvg, 'Mingle-it-Partner-Full')}
                onPng={() => dlPng(renderPartnerFull, 'Mingle-it-Partner-Full')}
              />
              <DownloadGroup
                label="오브젝트"
                color="bg-[#9900ff]"
                hoverColor="hover:bg-[#7a00cc]"
                onSvg={() => dlSvg(buildPartnerObjSvg, 'Mingle-it-Partner-Object')}
                onPng={() => dlPng(renderPartnerObj, 'Mingle-it-Partner-Object')}
              />
              <DownloadGroup
                label="배경"
                color="bg-[#9900ff]"
                hoverColor="hover:bg-[#7a00cc]"
                onSvg={() => dlSvgNoFont(buildPartnerBgSvg, 'Mingle-it-Partner-Background')}
                onPng={() => dlPng(renderPartnerBg, 'Mingle-it-Partner-Background')}
              />
            </div>
          </div>

          <div
            className={`p-8 rounded-3xl border shadow-lg text-center ${
              isDarkMode
                ? 'bg-slate-800/40 border-slate-800'
                : 'bg-white border-slate-100'
            }`}
          >
            <h3 className="text-lg font-racing italic uppercase mb-8 opacity-60 flex items-center justify-center gap-2">
              <Heart size={20} /> User Edition
            </h3>
            <div className="w-36 h-36 mx-auto rounded-[45%] shadow-xl overflow-hidden border border-slate-100">
              <div className="w-[144px] h-[144px] bg-white flex items-center justify-center p-[12px]">
                <div className="w-full h-full">
                  <MingleSymbol fillM="white" fillSpark={brandColors.secondary} useVibrantSystem={true} uniqueId="user-ui" />
                </div>
              </div>
            </div>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <DownloadGroup
                label="전체"
                color="bg-[#ff0080]"
                hoverColor="hover:bg-[#cc0066]"
                onSvg={() => dlSvg(buildUserFullSvg, 'Mingle-it-User-Full')}
                onPng={() => dlPng(renderUserFull, 'Mingle-it-User-Full')}
              />
              <DownloadGroup
                label="오브젝트"
                color="bg-[#ff0080]"
                hoverColor="hover:bg-[#cc0066]"
                onSvg={() => dlSvg(buildUserObjSvg, 'Mingle-it-User-Object')}
                onPng={() => dlPng(renderUserObj, 'Mingle-it-User-Object')}
              />
              <DownloadGroup
                label="배경"
                color="bg-[#ff0080]"
                hoverColor="hover:bg-[#cc0066]"
                onSvg={() => dlSvgNoFont(buildUserBgSvg, 'Mingle-it-User-Background')}
                onPng={() => dlPng(renderUserBg, 'Mingle-it-User-Background')}
              />
            </div>
          </div>
        </div>

        <section className="relative py-20 rounded-[50px] bg-mingle-free-flow text-center overflow-hidden">
          <div className="absolute inset-0 bg-black/40" />
          <div className="relative z-10 text-white font-racing italic uppercase text-5xl tracking-tighter">
            Every Ordinary <span className="text-white underline">Mingle</span>
          </div>
        </section>
      </main>
    </div>
  );
}
