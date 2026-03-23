import React, { useState } from "react";
import { Form, Input, Button, Card, Typography, message, Layout } from "antd";
import { LockOutlined, UserOutlined, SendOutlined } from "@ant-design/icons";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/userApi";
import { useNavigate } from "react-router-dom";
import { MdFlightTakeoff } from "react-icons/md";

const { Title, Text } = Typography;
const { Content } = Layout;

export default function Login() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);

    const onFinish = async ({ email, password }) => {
        setLoading(true);
        try {
            await signInWithEmailAndPassword(auth, email, password);
            // Optional: sync with backend
            try {
                await authApi.login();
            } catch (e) {
                console.warn("Backend sync skipped", e);
            }
            message.success("Logged in successfully!");
            navigate("/");
        } catch (error) {
            console.error("Login error", error);
            message.error("Login failed. Please check your credentials.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <Layout style={{ minHeight: "100vh", background: "#f0f2f5", display: "flex", justifyContent: "center", alignItems: "center" }}>
            <Content style={{ display: "flex", justifyContent: "center", alignItems: "center", width: "100%" }}>
                <Card style={{ width: "100%", maxWidth: 400, margin: "0 16px", borderRadius: 12, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}>
                    <div style={{ textAlign: "center", marginBottom: 30 }}>
                        <div style={{ background: "#1677ff", width: 60, height: 60, borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px" }}>
                            <MdFlightTakeoff style={{ color: "white", fontSize: 32 }} />
                        </div>
                        <Title level={3} style={{ margin: 0 }}>Vacanza Admin</Title>
                        <Text type="secondary">System Management Portal</Text>
                    </div>

                    <Form name="admin_login" onFinish={onFinish} layout="vertical" size="large">
                        <Form.Item
                            name="email"
                            rules={[{ required: true, message: "Please enter your email!" }, { type: "email" }]}
                        >
                            <Input prefix={<UserOutlined />} placeholder="Admin Email" />
                        </Form.Item>

                        <Form.Item
                            name="password"
                            rules={[{ required: true, message: "Please enter your password!" }]}
                        >
                            <Input.Password prefix={<LockOutlined />} placeholder="Password" />
                        </Form.Item>

                        <Form.Item style={{ marginTop: 24 }}>
                            <Button type="primary" htmlType="submit" block loading={loading}>
                                Log In to Dashboard
                            </Button>
                        </Form.Item>
                    </Form>

                    <div style={{ textAlign: "center", marginTop: 16 }}>
                        <Text type="secondary" size="small">Authorized personnel only</Text>
                    </div>
                </Card>
            </Content>
        </Layout>
    );
}
