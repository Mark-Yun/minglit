import React from 'react';

interface MinglitLogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export const MinglitLogo = ({ size = 'md', showText = true }: MinglitLogoProps) => {
  const sizeMap = {
    sm: { symbol: 'w-8 h-8 text-lg', text: 'text-xl' },
    md: { symbol: 'w-10 h-10 text-2xl', text: 'text-3xl' },
    lg: { symbol: 'w-16 h-16 text-4xl', text: 'text-5xl' },
  };

  const currentSize = sizeMap[size];

  return (
    <div className="flex items-center gap-3 select-none group">
      {/* Symbol */}
      <div className={`${currentSize.symbol} rounded-lg flex items-center justify-center relative overflow-hidden bg-gradient-to-br from-[#4F3CFF] to-[#9900ff] shadow-sm group-hover:rotate-6 transition-transform`}>
        <div className="absolute inset-0 bg-[linear-gradient(45deg,transparent_40%,#ffffff_40%,#ffffff_60%,transparent_60%)] mix-blend-overlay opacity-20" />
        <span 
          className="font-racing text-white relative z-10 -mt-[10%] -ml-[5%]"
          style={{ textShadow: '2px 2px 0px #21fffe, 3px 3px 0px #ff9900' }}
        >
          M
        </span>
      </div>

      {/* Text Logo */}
      {showText && (
        <span className={`font-racing ${currentSize.text} text-[#9900ff] tracking-wide transition-all`}>
          Minglit
        </span>
      )}
    </div>
  );
};
