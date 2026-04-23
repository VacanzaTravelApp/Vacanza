import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import './AuthLayout.css';
import webIcon from '../../web-icon.svg';

const calculateTimeState = () => {
  const now = new Date();
  const hours = now.getHours();
  const minutes = now.getMinutes();

  const isNight = hours < 6 || hours >= 20;

  let theme = isNight ? 'theme-midnight' : 'theme-sunrise';

  // Quick dynamic celestial calc based on time
  let cyclePeriod = isNight
    ? (hours >= 20 ? (hours - 20) + minutes / 60 : hours + 4 + minutes / 60) / 10
    : (hours - 6 + minutes / 60) / 14;

  const elevation = Math.sin(cyclePeriod * Math.PI);
  // Y ranges from 550 (below mountains) to 120 (high noon/midnight sky)
  const celestialY = 550 - (elevation * 430);

  const ampm = hours >= 12 ? 'PM' : 'AM';
  const hours12 = hours % 12 || 12;
  const formattedTime = `${hours12}:${minutes.toString().padStart(2, '0')} ${ampm}`;

  return { theme, isNight, celestialY, formattedTime };
};

const TravelScene = ({ timeState, isLoaded }) => {
  const { isNight, celestialY } = timeState;
  const CELESTIAL_X = 850;
  const currentY = isLoaded ? celestialY : 650;

  return (
    <svg className="travel-scene" viewBox="0 0 1000 600" preserveAspectRatio="xMidYMax slice" fill="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <mask id="moon-mask">
          <rect x="-200" y="-200" width="1500" height="1500" fill="white" />
          <circle cx="-25" cy="-20" r="80" fill="black" />
        </mask>
      </defs>

      {/* Stars - visible only at night */}
      <g className="night-stars parallax-bg" style={{ opacity: isNight && isLoaded ? 1 : 0, transition: 'opacity 3s ease 1s' }}>
        <circle cx="200" cy="150" r="2" fill="white" opacity="0.8" className="star-twinkle" />
        <circle cx="150" cy="80" r="2.5" fill="white" opacity="0.6" className="star-twinkle" style={{ animationDelay: '1s' }} />
        <circle cx="350" cy="120" r="1.5" fill="white" opacity="0.9" />
        <circle cx="650" cy="100" r="2.5" fill="white" opacity="0.7" className="star-twinkle" style={{ animationDelay: '0.5s' }} />
        <circle cx="800" cy="60" r="2" fill="white" opacity="0.5" />
        <circle cx="500" cy="180" r="1.5" fill="white" opacity="0.4" />
        <circle cx="900" cy="220" r="2" fill="white" opacity="0.6" className="star-twinkle" style={{ animationDelay: '1.5s' }} />
      </g>

      <g className="parallax-far">
        <g style={{ transform: `translate(${CELESTIAL_X}px, ${currentY}px)`, transition: 'transform 3s cubic-bezier(0.34, 1.2, 0.64, 1)' }}>
          {/* Core Shape: Sun or Moon */}
          <circle
            cx="0" cy="0" r="80"
            fill="var(--scene-sun)"
            opacity="0.95"
            mask={isNight ? "url(#moon-mask)" : undefined}
            className="celestial-pulse"
          />
          {/* Outer glows */}
          <circle cx="0" cy="0" r="100" fill="var(--scene-sun)" opacity={isNight ? 0.05 : 0.12} />
          <circle cx="0" cy="0" r="120" fill="var(--scene-sun)" opacity={isNight ? 0.02 : 0.06} />

          {/* Rays (Sun only) */}
          <g style={{ opacity: isNight ? 0 : 1, transition: 'opacity 1s ease' }}>
            <g className="sun-rays">
              {[0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330].map((a) => (
                <line key={a}
                  x1={90 * Math.cos(a * Math.PI / 180)} y1={90 * Math.sin(a * Math.PI / 180)}
                  x2={110 * Math.cos(a * Math.PI / 180)} y2={110 * Math.sin(a * Math.PI / 180)}
                  stroke="var(--scene-sun)" strokeWidth="3" strokeLinecap="round" opacity="0.35"
                />
              ))}
            </g>
          </g>
        </g>
      </g>

      {/* Premium High-Fidelity Clouds */}
      <g className="cloud cloud-1 parallax-mid" transform="translate(150, 120)">
        <path d="M 27 16 C 27 10 32 5 38 5 C 41 5 44 6 46 9 C 48 4 54 0 60 0 C 69 0 76 6 78 14 C 85 15 90 20 90 27 C 90 35 83 41 75 41 L 22 41 C 10 41 0 31 0 20 C 0 10 8 3 17 3 C 21 3 24 5 27 8 C 27 11 27 14 27 16 Z" fill="white" opacity="0.65" transform="scale(1.5)" />
      </g>
      <g className="cloud cloud-2 parallax-near" transform="translate(620, 80)">
        <path d="M 33 22 C 33 13 40 6 49 6 C 53 6 57 8 59 11 C 61 5 69 0 78 0 C 89 0 98 7 101 17 C 111 18 118 26 118 36 C 118 46 109 54 99 54 L 28 54 C 13 54 0 41 0 26 C 0 13 11 3 24 3 C 28 3 31 5 34 8 C 34 13 33 17 33 22 Z" fill="white" opacity="0.5" transform="scale(1.1)" />
      </g>
      <g className="cloud cloud-3 parallax-mid" transform="translate(820, 260)">
        <path d="M 17 11 C 17 6 21 3 26 3 C 28 3 30 4 32 6 C 33 3 37 0 42 0 C 49 0 54 4 56 10 C 61 11 65 15 65 20 C 65 25 61 30 55 30 L 16 30 C 7 30 0 23 0 14 C 0 6 5 2 11 2 C 14 2 16 3 18 5 C 18 7 17 9 17 11 Z" fill="white" opacity="0.4" transform="scale(1.6)" />
      </g>

      <path className="plane-trail parallax-far" d="M100,200 Q300,100 500,150 Q700,200 900,100"
        stroke="var(--scene-coral)" strokeWidth="2" strokeDasharray="8 10" fill="none" opacity="0.25" />
      <g className="parallax-far" transform="translate(900, 100) rotate(-15)">
        <polygon points="0,0 -20,-6 -15,0 -20,6" fill="var(--scene-navy)" opacity="0.3" />
      </g>

      <g className="balloon parallax-near" transform="translate(180, 300) scale(1.2)">
        <path d="M0,-42 C-32,-42 -38,-8 -26,24 L-14,36 L14,36 L26,24 C38,-8 32,-42 0,-42Z" fill="var(--scene-balloon)" />
        <path d="M-32,-12 Q0,-20 32,-12" fill="none" stroke="white" strokeWidth="4" opacity="0.55" />
        <path d="M-30,4 Q0,-3 30,4" fill="none" stroke="var(--scene-golden)" strokeWidth="3.5" opacity="0.5" />
        <path d="M-26,18 Q0,12 26,18" fill="none" stroke="var(--scene-accent)" strokeWidth="3" opacity="0.45" />
        <line x1="-14" y1="36" x2="-8" y2="50" stroke="#8B6914" strokeWidth="1" opacity="0.5" />
        <line x1="14" y1="36" x2="8" y2="50" stroke="#8B6914" strokeWidth="1" opacity="0.5" />
        <rect x="-9" y="50" width="18" height="10" rx="2.5" fill="#8B6914" opacity="0.6" />
      </g>

      <g className="parallax-bg">
        {/* Premium Layered Mountains with Organic Ridges */}
        <path d="M-50,600 L180,280 C190,265 210,265 220,280 L550,600 Z" fill="var(--scene-mt3)" opacity="0.5" />
        <path d="M156.5,312 L180,280 C190,265 210,265 220,280 L253.5,312 C230,318 215,330 200,310 C185,290 170,318 156.5,312 Z" fill="rgba(255,255,255,0.4)" />

        <path d="M200,600 L530,220 C540,205 560,205 570,220 L950,600 Z" fill="var(--scene-mt2)" opacity="0.6" />
        <path d="M496.5,258 L530,220 C540,205 560,205 570,220 L608.5,258 C590,270 570,250 550,265 C530,280 510,265 496.5,258 Z" fill="rgba(255,255,255,0.45)" />

        <path d="M600,600 L830,350 C840,335 860,335 870,350 L1150,600 Z" fill="var(--scene-mt1)" opacity="0.7" />
        <path d="M783.5,400 L830,350 C840,335 860,335 870,350 L926.5,400 C900,390 880,415 855,395 C835,380 805,405 783.5,400 Z" fill="rgba(255,255,255,0.35)" />
      </g>

      <g className="parallax-fg">
        <path className="wave wave-1" d="M-250,540 Q-125,560 0,540 T250,540 T500,540 T750,540 T1000,540 T1250,540 L1250,600 L-250,600Z" fill="var(--scene-ocean1)" opacity="0.55" />
        <path className="wave wave-2" d="M-250,560 Q-125,580 0,560 T250,560 T500,560 T750,560 T1000,560 T1250,560 L1250,600 L-250,600Z" fill="var(--scene-ocean2)" opacity="0.4" />
        <path className="wave wave-3" d="M-250,580 Q-125,590 0,580 T250,580 T500,580 T750,580 T1000,580 T1250,580 L1250,600 L-250,600Z" fill="var(--scene-ocean1)" opacity="0.3" />
      </g>

      <g className="sailboat parallax-near" transform="translate(700, 565) scale(1.3)">
        <path d="M-10,0 L10,0 L6,5 L-6,5Z" fill="var(--scene-navy)" opacity="0.3" />
        <line x1="0" y1="0" x2="0" y2="-18" stroke="var(--scene-navy)" strokeWidth="1" opacity="0.3" />
        <path d="M0,-18 L0,0 L12,-10Z" fill="white" opacity="0.45" />
      </g>
    </svg>
  );
};

const TinyCompass = () => (
  <img src={webIcon} className="tiny-compass" alt="Vacanza Icon" style={{ width: 32, height: 32 }} />
);

const PlaneIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="16" height="16" stroke="currentColor" strokeWidth="1.5">
    <path d="M21 16v-2l-8-5V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5l8 2.5z" fill="currentColor" opacity="0.8" />
  </svg>
);

const WalletIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="16" height="16" stroke="currentColor" strokeWidth="1.5">
    <rect x="3" y="6" width="18" height="12" rx="2" fill="currentColor" opacity="0.4" />
    <path d="M3 10h18M7 14h.01" strokeLinecap="round" />
  </svg>
);

const MapIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="16" height="16" stroke="currentColor" strokeWidth="1.5">
    <path d="M9 20l-6-3V4l6 3m0 13l6-3m-6 3V7m6 10l6 3V7l-6-3m0 13V4" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

const AuthLayout = ({ children }) => {
  const location = useLocation();
  const isLoginPage = location.pathname === '/login';
  const isVerifyPage = location.pathname === '/verify-email';
  const isConfirmEmailPage = location.pathname === '/confirm-email';
  const [timeState, setTimeState] = useState(calculateTimeState());
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    const raf = requestAnimationFrame(() => setIsLoaded(true));

    const handleMouseMove = (e) => {
      const { innerWidth, innerHeight } = window;
      const xPos = (e.clientX / innerWidth - 0.5) * 2;
      const yPos = (e.clientY / innerHeight - 0.5) * 2;

      document.documentElement.style.setProperty('--mouse-x', xPos);
      document.documentElement.style.setProperty('--mouse-y', yPos);
    };

    const timer = setInterval(() => setTimeState(calculateTimeState()), 60000);

    window.addEventListener('mousemove', handleMouseMove);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      clearInterval(timer);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <div className={`vivid-auth ${timeState.theme}`}>
      <div className="auth-background">
        <TravelScene timeState={timeState} isLoaded={isLoaded} />
      </div>

      <div className="auth-content-layer">
        <header className="vivid-topbar">
          <div className="topbar-left">
            <TinyCompass />
            <span className="brand-name">Vacanza</span>
            <span className="local-time-badge">{timeState.formattedTime}</span>
          </div>
          <span className="brand-tagline">Travel Intelligently</span>
        </header>

        <div className="floating-ornaments">
          <div className="poster-text float-top-left">
            <h1 className="vivid-title">
              {isConfirmEmailPage ? (
                <>Inbox<br /><span className="title-accent">Link</span></>
              ) : isVerifyPage ? (
                <>One More<br /><span className="title-accent">Step</span></>
              ) : isLoginPage ? (
                <>Welcome<br /><span className="title-accent">Back</span></>
              ) : (
                <>Begin Your<br /><span className="title-accent">Journey</span></>
              )}
            </h1>
            <p className="poster-subtitle">
              {isConfirmEmailPage
                ? 'Secure steps from your email, right here.'
                : isVerifyPage
                  ? 'Confirm your email to unlock the full experience.'
                  : isLoginPage
                    ? 'Your plans are waiting.'
                    : 'AI-powered travel planning.'}
            </p>
          </div>

          <div className="vivid-stats float-bottom-left">
            <div className="stat-item">
              <span className="stat-number">500K+</span>
              <span className="stat-label">Routes</span>
            </div>
            <div className="stat-divider" />
            <div className="stat-item">
              <span className="stat-number">120+</span>
              <span className="stat-label">Countries</span>
            </div>
            <div className="stat-divider" />
            <div className="stat-item">
              <span className="stat-number">4.8★</span>
              <span className="stat-label">Rating</span>
            </div>
          </div>

          <div className="vivid-features float-bottom-right">
            <div className="feature-card subtle-hover">
              <span className="feature-icon"><PlaneIcon /></span>
              <span className="feature-name">Smart Routes</span>
            </div>
            <div className="feature-card subtle-hover">
              <span className="feature-icon"><WalletIcon /></span>
              <span className="feature-name">Budget Planner</span>
            </div>
            <div className="feature-card subtle-hover">
              <span className="feature-icon"><MapIcon /></span>
              <span className="feature-name">Live Maps</span>
            </div>
          </div>
        </div>

        <div className="vivid-form-wrapper">
          {children}
        </div>
      </div>
    </div>
  );
};

export default AuthLayout;