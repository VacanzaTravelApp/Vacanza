import React, { useState } from "react";
import { Form, Input, Button, Card, Typography, message, Layout, Space } from "antd";
import { LockOutlined, UserOutlined, ArrowRightOutlined } from "@ant-design/icons";
import { signInWithEmailAndPassword, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/userApi";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";

const { Title, Text } = Typography;
const { Content } = Layout;

const THEME = {
    navy: '#1A2332',
    coral: '#FF6B6B',
    teal: '#00B4D8',
    subtext: '#5A6B7A',
    glass: 'rgba(255, 255, 255, 0.95)'
};

export default function Login() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);

    const onFinish = async ({ email, password }) => {
        setLoading(true);
        try {
            // 1. Firebase authentication
            await signInWithEmailAndPassword(auth, email, password);

            // 2. Sync with backend and get user data (includes role from DB)
            const res = await authApi.login();
            const userData = res.data;

            // 3. Check if user has ADMIN role in DB
            if (!userData?.role || userData.role !== 'ADMIN') {
                message.error("Access denied. You do not have administrator privileges.");
                await signOut(auth);
                return;
            }

            message.success("Authentication verified. Establishing secure administrative session...");
            // We don't navigate manually anymore. 
            // AuthProvider will detect the login and App.jsx will redirect once authenticated.
        } catch (error) {
            console.error("Login error", error);
            // Firebase sign out on any failure
            try { await signOut(auth); } catch (_) { }

            if (error.code === 'auth/user-not-found') {
                message.error("No account found with this email address.");
            } else if (error.code === 'auth/wrong-password' || error.code === 'auth/invalid-credential') {
                message.error("Incorrect email or password. Please try again.");
            } else if (error.code === 'auth/too-many-requests') {
                message.error("Too many failed attempts. Please wait a few minutes.");
            } else if (error?.response?.status === 401) {
                message.error("Authentication failed. Please check your credentials.");
            } else if (error?.response?.status === 403) {
                message.error("Access denied. Your account is not verified or authorized.");
            } else {
                message.error("Login failed. Please check your credentials.");
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <Layout style={{ minHeight: "100vh", background: THEME.navy, overflow: 'hidden', position: 'relative' }}>
            {/* Background Pattern */}
            <div style={{
                position: 'absolute', width: '100%', height: '100%',
                opacity: 0.05, pointerEvents: 'none',
                background: 'radial-gradient(circle at 2px 2px, rgba(255,255,255,0.15) 1px, transparent 0)',
                backgroundSize: '40px 40px'
            }} />

            <Content style={{ display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1 }}>
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.6 }}
                >
                    <Card
                        bordered={false}
                        style={{
                            width: 440,
                            borderRadius: 32,
                            boxShadow: "0 40px 100px rgba(0,0,0,0.4)",
                            background: THEME.glass,
                            padding: '24px'
                        }}
                    >
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 32 }}>
                            <img src="/logo.svg" alt="Logo" style={{ width: 100, height: 100, objectFit: 'contain', marginBottom: 16 }} />
                            <div style={{ textAlign: 'center' }}>
                                <div style={{
                                    color: THEME.navy,
                                    fontSize: '28px',
                                    fontWeight: 800,
                                    letterSpacing: '4px',
                                    fontFamily: "'DM Sans', sans-serif"
                                }}>
                                    VACANZA
                                </div>
                                <div style={{
                                    color: THEME.primary,
                                    fontSize: '12px',
                                    fontWeight: 700,
                                    letterSpacing: '3px',
                                    opacity: 0.8,
                                    marginTop: '-4px'
                                }}>
                                    ADMINISTRATIVE CONSOLE
                                </div>
                            </div>
                        </div>

                        <Form name="admin_login" onFinish={onFinish} layout="vertical" size="large">
                            <Form.Item
                                name="email"
                                rules={[
                                    { required: true, message: "Please enter your administrative email address" },
                                    { type: "email", message: "Please provide a valid email format" }
                                ]}
                            >
                                <Input
                                    prefix={<UserOutlined style={{ color: THEME.coral }} />}
                                    placeholder="Operator Email"
                                    style={{ borderRadius: 14, height: 56, background: '#f8faff' }}
                                />
                            </Form.Item>

                            <Form.Item
                                name="password"
                                rules={[{ required: true, message: "Please enter your password" }]}
                            >
                                <Input.Password
                                    prefix={<LockOutlined style={{ color: THEME.coral }} />}
                                    placeholder="Password"
                                    style={{ borderRadius: 14, height: 56, background: '#f8faff' }}
                                />
                            </Form.Item>

                            <Form.Item style={{ marginTop: 40, marginBottom: 0 }}>
                                <Button
                                    type="primary"
                                    htmlType="submit"
                                    block
                                    loading={loading}
                                    style={{
                                        height: 60,
                                        borderRadius: 18,
                                        fontSize: 17,
                                        fontWeight: 800,
                                        background: THEME.navy,
                                        border: 'none',
                                        boxShadow: '0 10px 30px rgba(26, 35, 50, 0.3)'
                                    }}
                                >
                                    Secure Login
                                </Button>
                            </Form.Item>
                        </Form>

                        <div style={{ textAlign: "center", marginTop: 32 }}>
                            <Text style={{ fontSize: 11, color: THEME.subtext, opacity: 0.6, letterSpacing: 1.5, fontWeight: 700 }}>
                                © 2026 VACANZA INFRASTRUCTURE SECURED
                            </Text>
                        </div>
                    </Card>
                </motion.div>
            </Content>
        </Layout>
    );
}
