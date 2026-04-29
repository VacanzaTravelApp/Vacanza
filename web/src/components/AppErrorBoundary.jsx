import React from "react";

export default class AppErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error, info) {
    console.error("[AppErrorBoundary]", error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          height: "100vh",
          gap: "16px",
          fontFamily: "sans-serif",
          color: "#e0e0e0",
          background: "#0f1117",
        }}>
          <p style={{ fontSize: "16px", color: "#9ca3af" }}>
            Something went wrong. Please refresh the page.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: "10px 24px",
              borderRadius: "10px",
              border: "none",
              background: "#3b82f6",
              color: "#fff",
              fontSize: "14px",
              fontWeight: "600",
              cursor: "pointer",
            }}
          >
            Refresh
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
