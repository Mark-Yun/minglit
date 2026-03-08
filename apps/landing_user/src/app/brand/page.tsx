'use client';

import React, { useRef, useState } from 'react';
import { Download, Sun, Moon } from 'lucide-react';
import { toPng } from 'html-to-image';

const SPARK_PATH =
  'M50 2C52 35 65 48 98 50C65 52 52 65 50 98C48 65 35 52 2 50C35 48 48 35 50 2Z';

const Sparkle = ({
  className,
  style,
  fill = 'url(#mingleMultiRadial)',
}: {
  className?: string;
  style?: React.CSSProperties;
  fill?: string;
}) => (
  <svg viewBox="0 0 100 100" className={className} style={style} fill={fill}>
    <path d={SPARK_PATH} />
  </svg>
);

const brandColors = {
  primary: '#9900ff',
  secondary: '#ff9900',
  accent: '#ff0080',
  highlight: '#d185ff',
};

const EXPORT_SIZE = 1024;

async function captureElement(
  el: HTMLElement | null,
  fileName: string,
  pixelRatio = EXPORT_SIZE / 144,
) {
  if (!el) return;
  const dataUrl = await toPng(el, {
    pixelRatio,
    cacheBust: true,
  });
  const link = document.createElement('a');
  link.href = dataUrl;
  link.download = `${fileName}.png`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

async function captureWithoutBg(
  containerEl: HTMLElement | null,
  objectsEl: HTMLElement | null,
  fileName: string,
  pixelRatio = EXPORT_SIZE / 144,
) {
  if (!containerEl || !objectsEl) return;
  const savedClasses = [...containerEl.classList];
  const origBg = containerEl.style.background;
  const origBgColor = containerEl.style.backgroundColor;
  containerEl.style.background = 'transparent';
  containerEl.style.backgroundColor = 'transparent';
  containerEl.classList.remove('bg-mingle-free-flow', 'bg-white');
  try {
    const dataUrl = await toPng(containerEl, { pixelRatio, cacheBust: true });
    const link = document.createElement('a');
    link.href = dataUrl;
    link.download = `${fileName}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } finally {
    containerEl.className = savedClasses.join(' ');
    containerEl.style.background = origBg;
    containerEl.style.backgroundColor = origBgColor;
  }
}

async function captureBgOnly(
  containerEl: HTMLElement | null,
  objectsEl: HTMLElement | null,
  fileName: string,
  pixelRatio = EXPORT_SIZE / 144,
) {
  if (!containerEl || !objectsEl) return;
  const origDisplay = objectsEl.style.display;
  objectsEl.style.display = 'none';
  try {
    const dataUrl = await toPng(containerEl, { pixelRatio, cacheBust: true });
    const link = document.createElement('a');
    link.href = dataUrl;
    link.download = `${fileName}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } finally {
    objectsEl.style.display = origDisplay;
  }
}

export default function BrandPage() {
  const [isDarkMode, setIsDarkMode] = useState(false);

  const gradientContainerRef = useRef<HTMLDivElement>(null);
  const gradientObjectsRef = useRef<HTMLDivElement>(null);
  const minimalContainerRef = useRef<HTMLDivElement>(null);
  const minimalObjectsRef = useRef<HTMLDivElement>(null);

  return (
    <div
      className={`min-h-screen flex flex-col transition-colors duration-300 ${
        isDarkMode ? 'bg-[#0a0510] text-white' : 'bg-white text-slate-900'
      }`}
    >
      <svg width="0" height="0" className="absolute">
        <defs>
          <radialGradient id="mingleMultiRadial" cx="50%" cy="50%" r="80%" fx="20%" fy="20%">
            <stop offset="0%" stopColor={brandColors.highlight} />
            <stop offset="35%" stopColor={brandColors.primary} />
            <stop offset="75%" stopColor={brandColors.accent} />
            <stop offset="100%" stopColor={brandColors.secondary} />
          </radialGradient>
          <linearGradient id="gradPurple" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor={brandColors.highlight} />
            <stop offset="100%" stopColor={brandColors.primary} />
          </linearGradient>
          <linearGradient id="gradMagenta" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor={brandColors.accent} />
            <stop offset="100%" stopColor={brandColors.primary} />
          </linearGradient>
          <linearGradient id="gradOrange" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor={brandColors.secondary} />
            <stop offset="100%" stopColor={brandColors.accent} />
          </linearGradient>
        </defs>
      </svg>

      <header
        className={`p-6 flex justify-between items-center border-b ${
          isDarkMode ? 'border-slate-800' : 'border-slate-100'
        }`}
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-mingle-free-flow flex items-center justify-center">
            <Sparkle className="w-6 h-6" fill="white" />
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
              <Sparkle
                className="absolute top-[5%] left-[5%] w-44 h-44 pulse-1"
              />
              <Sparkle
                className="absolute top-[20%] right-[10%] w-28 h-28 pulse-2"
                style={{ filter: 'brightness(1.1)' }}
              />
              <Sparkle
                className="absolute bottom-[10%] right-[25%] w-20 h-20 pulse-3"
                style={{ filter: 'saturate(1.2)' }}
              />
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
            <h3 className="text-lg font-racing italic uppercase mb-8 opacity-60">
              Full Gradient Icon
            </h3>
            <div className="w-36 h-36 mx-auto rounded-[36%] shadow-2xl overflow-hidden">
              <div
                ref={gradientContainerRef}
                className="relative w-full h-full bg-mingle-free-flow flex items-center justify-center"
              >
                <div ref={gradientObjectsRef} className="relative w-28 h-28">
                  <Sparkle className="absolute top-0 left-0 w-20 h-20" fill="white" />
                  <Sparkle className="absolute top-8 right-1 w-12 h-12 opacity-80" fill="white" />
                  <Sparkle className="absolute bottom-1 right-6 w-9 h-9 opacity-60" fill="white" />
                </div>
              </div>
            </div>
            <div className="mt-8 flex flex-wrap justify-center gap-2">
              <button
                onClick={() => captureElement(gradientContainerRef.current, 'Mingle-it-Gradient-Full')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 전체
              </button>
              <button
                onClick={() => captureWithoutBg(gradientContainerRef.current, gradientObjectsRef.current, 'Mingle-it-Gradient-Object')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 오브젝트
              </button>
              <button
                onClick={() => captureBgOnly(gradientContainerRef.current, gradientObjectsRef.current, 'Mingle-it-Gradient-Background')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 배경
              </button>
            </div>
          </div>

          <div
            className={`p-8 rounded-3xl border shadow-lg text-center ${
              isDarkMode
                ? 'bg-slate-800/40 border-slate-800'
                : 'bg-white border-slate-100'
            }`}
          >
            <h3 className="text-lg font-racing italic uppercase mb-8 opacity-60">
              Minimal Shadow Icon
            </h3>
            <div className="w-36 h-36 mx-auto rounded-[36%] shadow-xl overflow-hidden border border-slate-50">
              <div
                ref={minimalContainerRef}
                className="relative w-full h-full flex items-center justify-center"
                style={{ backgroundColor: '#f8f0fd' }}
              >
                <svg width="0" height="0" className="absolute">
                  <defs>
                    <linearGradient id="capGradPurple" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor={brandColors.highlight} />
                      <stop offset="100%" stopColor={brandColors.primary} />
                    </linearGradient>
                    <linearGradient id="capGradMagenta" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor={brandColors.accent} />
                      <stop offset="100%" stopColor={brandColors.primary} />
                    </linearGradient>
                    <linearGradient id="capGradOrange" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor={brandColors.secondary} />
                      <stop offset="100%" stopColor={brandColors.accent} />
                    </linearGradient>
                  </defs>
                </svg>
                <div ref={minimalObjectsRef} className="relative w-28 h-28 clean-long-shadow">
                  <Sparkle className="absolute top-0 left-0 w-20 h-20" style={{ fill: 'url(#capGradPurple)' }} />
                  <Sparkle className="absolute top-8 right-1 w-12 h-12 opacity-80" style={{ fill: 'url(#capGradMagenta)' }} />
                  <Sparkle className="absolute bottom-1 right-6 w-9 h-9 opacity-60" style={{ fill: 'url(#capGradOrange)' }} />
                </div>
              </div>
            </div>
            <div className="mt-8 flex flex-wrap justify-center gap-2">
              <button
                onClick={() => captureElement(minimalContainerRef.current, 'Mingle-it-Minimal-Full')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 전체
              </button>
              <button
                onClick={() => captureWithoutBg(minimalContainerRef.current, minimalObjectsRef.current, 'Mingle-it-Minimal-Object')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 오브젝트
              </button>
              <button
                onClick={() => captureBgOnly(minimalContainerRef.current, minimalObjectsRef.current, 'Mingle-it-Minimal-Background')}
                className="px-4 py-2 bg-slate-100 hover:bg-[#9900ff] hover:text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5"
              >
                <Download size={12} /> 배경
              </button>
            </div>
          </div>
        </div>

        <section className="relative py-20 rounded-[50px] bg-mingle-free-flow text-center overflow-hidden">
          <div className="absolute inset-0 bg-black/40" />
          <div className="relative z-10 text-white font-racing italic uppercase text-5xl tracking-tighter">
            Every Ordinary <span className="text-white underline">Spark</span>
          </div>
        </section>
      </main>
    </div>
  );
}
