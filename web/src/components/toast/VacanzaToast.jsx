import React, {
  useState, useCallback, useRef, useEffect,
  useImperativeHandle, forwardRef,
} from 'react';
import { createPortal } from 'react-dom';
import { _setToastRef } from './toast';
import './VacanzaToast.css';

const DURATIONS = { error: 5000, success: 3000, warning: 4500, info: 5000 };

const ICONS = {
  error: (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round">
      <circle cx="10" cy="10" r="8.5" />
      <path d="M7.5 7.5l5 5M12.5 7.5l-5 5" />
    </svg>
  ),
  success: (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="10" cy="10" r="8.5" />
      <path d="M6.5 10.5l2.5 2.5 4.5-5" />
    </svg>
  ),
  warning: (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10 2.5L17.5 16H2.5L10 2.5z" />
      <path d="M10 8.5v3" />
      <circle cx="10" cy="14" r="0.7" fill="currentColor" stroke="none" />
    </svg>
  ),
  info: (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round">
      <circle cx="10" cy="10" r="8.5" />
      <path d="M10 9.5v4.5" />
      <circle cx="10" cy="6.5" r="0.7" fill="currentColor" stroke="none" />
    </svg>
  ),
};

let _id = 0;

const ToastItem = ({ id, type, title, message, duration, onRemove }) => {
  const [exiting, setExiting] = useState(false);
  const timerRef = useRef(null);
  const dur = duration ?? DURATIONS[type] ?? 4000;

  const dismiss = useCallback(() => {
    clearTimeout(timerRef.current);
    setExiting(true);
  }, []);

  useEffect(() => {
    timerRef.current = setTimeout(dismiss, dur);
    return () => clearTimeout(timerRef.current);
  }, []);

  const onAnimEnd = (e) => {
    if (e.animationName === 'vc-slide-out') onRemove(id);
  };

  return (
    <div
      className={`vc-toast vc-toast--${type}${exiting ? ' vc-toast--exit' : ''}`}
      onAnimationEnd={onAnimEnd}
      role="alert"
      aria-live="polite"
    >
      <div className="vc-toast__stripe" />
      <div className="vc-toast__icon">{ICONS[type]}</div>
      <div className="vc-toast__body">
        {title && <p className="vc-toast__title">{title}</p>}
        <p className="vc-toast__msg">{message}</p>
      </div>
      <button className="vc-toast__close" onClick={dismiss} aria-label="Dismiss">
        <svg viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
          <path d="M1 1l8 8M9 1L1 9" />
        </svg>
      </button>
      <div className="vc-toast__bar" style={{ animationDuration: `${dur}ms` }} />
    </div>
  );
};

const VacanzaToastContainer = forwardRef((_, ref) => {
  const [toasts, setToasts] = useState([]);

  useImperativeHandle(ref, () => ({
    add(opts) {
      const id = ++_id;
      setToasts(prev => {
        const next = [...prev, { id, ...opts }];
        return next.length > 4 ? next.slice(next.length - 4) : next;
      });
    },
  }));

  const remove = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  return createPortal(
    <div className="vc-toast-portal" aria-label="Notifications">
      {toasts.map(t => <ToastItem key={t.id} {...t} onRemove={remove} />)}
    </div>,
    document.body,
  );
});

VacanzaToastContainer.displayName = 'VacanzaToastContainer';

export function VacanzaToastProvider({ children }) {
  const ref = useRef(null);

  useEffect(() => {
    _setToastRef(ref.current);
    return () => _setToastRef(null);
  }, []);

  return (
    <>
      {children}
      <VacanzaToastContainer ref={ref} />
    </>
  );
}
