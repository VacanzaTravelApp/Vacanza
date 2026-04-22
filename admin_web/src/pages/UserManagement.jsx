import React from "react";
import { Table, Tag, Card, Button, Input, Space, message, Typography, Avatar, Tooltip, Row, Col } from "antd";
import { SearchOutlined, UserOutlined, RocketFilled, VerifiedOutlined, SafetyCertificateFilled } from "@ant-design/icons";
import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";
import { motion } from "framer-motion";

const { Title, Text } = Typography;

const THEME = {
    primary: '#6366f1',
    admin: '#722ed1',
    user: '#1677ff',
    success: '#52c41a',
    bg: '#f8fafc',
    navy: '#1A2332',
    subtext: '#5A6B7A'
};

export default function UserManagement() {
    const [searchText, setSearchText] = React.useState("");
    const [manualEmail, setManualEmail] = React.useState("");

    const { data: users, isLoading, refetch } = useQuery({
        queryKey: ["all-users"],
        queryFn: async () => {
            const res = await userApi.getAllUsers();
            return res.data;
        },
    });

    const handlePromote = async (email) => {
        if (!email) return;
        try {
            message.loading({ content: "Elevating user privileges...", key: "promote", duration: 0 });
            await userApi.promoteUserToAdmin(email);
            message.success({ content: `User ${email} promoted to ADMIN successfully!`, key: "promote" });
            refetch();
            setManualEmail("");
        } catch (error) {
            const errorMsg = error.response?.data?.message || "Failed to promote user.";
            message.error({ content: errorMsg, key: "promote" });
        }
    };

    const filteredUsers = React.useMemo(() => {
        if (!users) return [];
        return users.filter(u =>
            u.user?.displayName?.toLowerCase().includes(searchText.toLowerCase()) ||
            u.user?.email?.toLowerCase().includes(searchText.toLowerCase())
        );
    }, [users, searchText]);

    const columns = [
        {
            title: "Identity",
            key: "identity",
            width: 250,
            fixed: 'left',
            render: (_, record) => (
                <Space size="middle">
                    <div style={{
                        width: 36,
                        height: 36,
                        borderRadius: '8px',
                        background: 'rgba(26, 35, 50, 0.03)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        border: '1px dashed rgba(26, 35, 50, 0.1)'
                    }}>
                        <UserOutlined style={{ color: THEME.subtext, opacity: 0.5, fontSize: 14 }} />
                    </div>
                    <div style={{ maxWidth: 180 }}>
                        <Text strong style={{ color: THEME.navy, fontSize: 13, display: 'block' }} ellipsis>{record.user?.displayName || "Anonymous"}</Text>
                        <Text type="secondary" style={{ fontSize: 11, display: 'block' }} ellipsis>{record.user?.email}</Text>
                    </div>
                </Space>
            ),
        },
        {
            title: "Access Privileges",
            dataIndex: ["user", "role"],
            key: "role",
            width: 150,
            render: (role) => {
                const isAdmin = role === "ADMIN";
                return (
                    <Tag
                        variant="filled"
                        color={isAdmin ? "purple" : "blue"}
                        icon={isAdmin ? <SafetyCertificateFilled /> : <UserOutlined />}
                        style={{
                            borderRadius: '12px',
                            padding: '2px 10px',
                            fontWeight: 700,
                            fontSize: 10,
                            border: 'none',
                            textTransform: 'uppercase'
                        }}
                    >
                        {role || "USER"}
                    </Tag>
                );
            }
        },
        {
            title: "Connectivity",
            dataIndex: "authenticated",
            key: "authenticated",
            width: 140,
            render: (auth) => (
                <Space>
                    {auth ? (
                        <Tag variant="filled" color="success" icon={<VerifiedOutlined />} style={{ borderRadius: 6, border: 'none', background: 'rgba(82, 196, 26, 0.1)', fontSize: 10 }}>
                            Active Node
                        </Tag>
                    ) : (
                        <Tag variant="filled" color="default" style={{ fontSize: 10 }}>Legacy</Tag>
                    )}
                </Space>
            )
        },
        {
            title: "System Actions",
            key: "actions",
            align: 'right',
            width: 180,
            render: (_, record) => (
                <Space size="middle">
                    {record.user?.role !== "ADMIN" ? (
                        <Tooltip title="Elevate to Administrative Role">
                            <Button
                                type="primary"
                                icon={<RocketFilled />}
                                onClick={() => handlePromote(record.user?.email)}
                                style={{
                                    borderRadius: '8px',
                                    background: THEME.admin,
                                    borderColor: THEME.admin,
                                    fontWeight: 600,
                                    fontSize: 11,
                                    height: 32
                                }}
                            >
                                Promote
                            </Button>
                        </Tooltip>
                    ) : (
                        <Text style={{ color: THEME.admin, fontWeight: 700, fontSize: 10, fontStyle: 'italic', opacity: 0.5 }}>
                            High Authority
                        </Text>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: "clamp(12px, 3vw, 24px)" }}>
            <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} style={{ marginBottom: "clamp(24px, 5vw, 48px)" }}>
                <Row gutter={[16, 16]} align="middle">
                    <Col xs={24} md={16}>
                        <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '16px', marginBottom: 8 }}>
                            <Title
                                className="gradient-text"
                                style={{
                                    fontSize: 'clamp(28px, 4vw, 36px)',
                                    margin: 0,
                                    fontFamily: "'Fraunces', serif",
                                    fontWeight: 900,
                                    letterSpacing: '-1px'
                                }}
                            >
                                Directory Node Explorer
                            </Title>
                            <div style={{ padding: '4px 12px', background: 'rgba(99, 102, 241, 0.05)', borderRadius: '24px', border: '1px solid rgba(99, 102, 241, 0.1)' }}>
                                <Text strong style={{ color: THEME.primary, fontSize: 12 }}>{users?.length || 0} Nodes</Text>
                            </div>
                        </div>
                        <Text
                            style={{
                                color: THEME.subtext,
                                fontSize: 'clamp(14px, 2vw, 16px)',
                                fontWeight: 500,
                                fontFamily: "'DM Sans', sans-serif",
                                maxWidth: '750px',
                                display: 'block',
                                lineHeight: 1.5
                            }}
                        >
                            Manage unified user identities across the Vacanza infrastructure. Review authentication status and privilege elevation for node administrators.
                        </Text>
                    </Col>
                </Row>
            </motion.div>

            <Row gutter={[24, 24]}>
                <Col xs={24} xl={16}>
                    <Card
                        bordered={false}
                        className="glass-card"
                        styles={{ body: { padding: "clamp(12px, 2vw, 24px)" } }}
                        title={
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 16 }}>
                                <span style={{ fontSize: 18, color: THEME.navy }}>Unified Identity Table</span>
                                <Input
                                    placeholder="Search nodes..."
                                    prefix={<SearchOutlined style={{ color: THEME.subtext }} />}
                                    value={searchText}
                                    onChange={e => setSearchText(e.target.value)}
                                    style={{ width: 'clamp(200px, 100%, 300px)', borderRadius: '10px' }}
                                />
                            </div>
                        }
                    >
                        <Table
                            columns={columns}
                            dataSource={filteredUsers}
                            loading={isLoading}
                            rowKey={(record) => record.user?.userId || record.user?.email}
                            pagination={{ pageSize: 8, showSizeChanger: false, size: 'small' }}
                            style={{ overflow: 'hidden' }}
                            scroll={{ x: 700 }}
                        />
                    </Card>
                </Col>

                <Col xs={24} xl={8}>
                    <Card
                        className="glass-card"
                        bordered={false}
                        title={<span style={{ fontSize: 18, color: THEME.navy }}>Quick Privilege Elevation</span>}
                        styles={{ body: { padding: "clamp(16px, 3vw, 24px)" } }}
                    >
                        <div style={{ marginBottom: 24 }}>
                            <Text type="secondary" style={{ fontSize: 13, display: 'block', marginBottom: 20 }}>
                                Manually grant administrative access to any user node by email or identity hash.
                            </Text>
                            <Input
                                size="large"
                                placeholder="identity@vacanza.com"
                                value={manualEmail}
                                onChange={(e) => setManualEmail(e.target.value)}
                                prefix={<UserOutlined style={{ color: THEME.primary }} />}
                                style={{ borderRadius: '14px', marginBottom: 16, height: 48 }}
                            />
                            <Button
                                type="primary"
                                block
                                size="large"
                                icon={<RocketFilled />}
                                onClick={() => {
                                    if (!manualEmail) return message.warning("Please specify an identity email.");
                                    handlePromote(manualEmail);
                                }}
                                style={{
                                    backgroundColor: THEME.admin,
                                    borderColor: THEME.admin,
                                    height: 48,
                                    borderRadius: '14px',
                                    fontWeight: 700,
                                    boxShadow: '0 10px 20px rgba(114, 46, 209, 0.15)'
                                }}
                            >
                                Grand ADMIN Status
                            </Button>
                        </div>

                        <div style={{
                            padding: '16px',
                            background: 'rgba(114, 46, 209, 0.03)',
                            borderRadius: '16px',
                            border: '1px dashed rgba(114, 46, 209, 0.2)'
                        }}>
                            <Title level={5} style={{ fontSize: 11, color: THEME.admin, textTransform: 'uppercase', letterSpacing: 1, margin: '0 0 8px 0' }}>Authority Warning</Title>
                            <Text style={{ fontSize: 12, color: THEME.subtext, lineHeight: 1.5 }}>
                                Promoting a user to <b>ADMIN</b> grants full access to system monitoring, user directory, and global telemetry controls.
                            </Text>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
