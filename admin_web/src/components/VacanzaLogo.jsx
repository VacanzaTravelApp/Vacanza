import React from 'react';

const VacanzaLogo = ({ size = 44, color = '#1A2332', showText = false }) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <svg
            width={size}
            height={size}
            viewBox="0 0 100 100"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            style={{ flexShrink: 0 }}
        >
            {/* Outer Circle */}
            <circle cx="50" cy="50" r="45" stroke="#94a3b8" strokeWidth="2.5" />

            {/* North/South Needles */}
            <path d="M50 15L56 42H44L50 15Z" fill="#94a3b8" />
            <path d="M50 85L44 58H56L50 85Z" fill="#e2e8f0" />

            {/* Center Red Dot */}
            <circle cx="50" cy="50" r="8" fill="#FF6B6B" stroke="white" strokeWidth="2" />
        </svg>
        {showText && (
            <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
                <span style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: size * 0.55,
                    fontWeight: 900,
                    color: color,
                    letterSpacing: '-1px'
                }}>
                    Vacanza
                </span>
                <span style={{
                    fontSize: '10px',
                    letterSpacing: 2.5,
                    fontWeight: 800,
                    color: '#FF6B6B',
                    textTransform: 'uppercase',
                    marginTop: -2
                }}>
                    Admin Console
                </span>
            </div>
        )}
    </div>
);

export default VacanzaLogo;
