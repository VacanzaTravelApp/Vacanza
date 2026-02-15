import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import "antd/dist/reset.css";
import "./index.css";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import AuthProvider from "./context/AuthProvider";

const queryClient = new QueryClient();

console.log("MAIN JSX RUNNING");

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <AuthProvider>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </AuthProvider>
  </React.StrictMode>
);
