import React from "react";
import { Table, Tag, Card, Button, Input, Space, message, Typography, Avatar, Tooltip, Row, Col } from "antd";
import { SearchOutlined, UserOutlined, EditOutlined, DeleteOutlined, RocketFilled, VerifiedOutlined, SafetyCertificateFilled } from "@ant-design/icons";
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
            width: '35%',
            render: (_, record) => (
                <Space size="middle">
                    <div style={{
                        width: 40,
                        height: 40,
                        borderRadius: '10px',
                        background: 'rgba(26, 35, 50, 0.03)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        border: '1px dashed rgba(26, 35, 50, 0.1)'
                    }}>
                        <UserOutlined style={{ color: THEME.subtext, opacity: 0.5 }} />
                    </div>
                    <div>
                        <Text strong style={{ color: THEME.navy, fontSize: 14 }}>{record.user?.displayName || "Anonymous"}</Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: 12 }}>{record.user?.email}</Text>
                    </div>
                </Space>
            ),
        },
        {
            title: "Access Privileges",
            dataIndex: ["user", "role"],
            key: "role",
            width: '150px',
            render: (role) => {
                const isAdmin = role === "ADMIN";
                return (
                    <Tag
                        color={isAdmin ? "purple" : "blue"}
                        icon={isAdmin ? <SafetyCertificateFilled /> : <UserOutlined />}
                        style={{
                            borderRadius: '12px',
                            padding: '4px 12px',
                            fontWeight: 700,
                            letterSpacing: 0.5,
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
            width: '150px',
            render: (auth) => (
                <Space>
                    {auth ? (
                        <Tag color="success" icon={<VerifiedOutlined />} style={{ borderRadius: 6, border: 'none', background: 'rgba(82, 196, 26, 0.1)' }}>
                            Active Node
                        </Tag>
                    ) : (
                        <Tag color="default">Legacy</Tag>
                    )}
                </Space>
            )
        },
        {
            title: "System Actions",
            key: "actions",
            align: 'right',
            render: (_, record) => (
                <Space size="middle">
                    {record.user?.role !== "ADMIN" ? (
                        <Tooltip title="Elevate to Administrative Role">
                            <Button
                                type="primary"
                                icon={<RocketFilled />}
                                onClick={() => handlePromote(record.user?.email)}
                                style={{
                                    borderRadius: '10px',
                                    background: THEME.admin,
                                    borderColor: THEME.admin,
                                    fontWeight: 600,
                                    fontSize: 12
                                }}
                            >
                                Promote to Admin
                            </Button>
                        </Tooltip>
                    ) : (
                        <Text style={{ color: THEME.admin, fontWeight: 700, fontSize: 11, fontStyle: 'italic', opacity: 0.5 }}>
                            High-Level Authority
                        </Text>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: "16px" }}>
            <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} style={{ marginBottom: 48 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: 12 }}>
                    <Title
                        className="gradient-text"
                        style={{
                            fontSize: '36px',
                            margin: 0,
                            fontFamily: "'Fraunces', serif",
                            fontWeight: 900,
                            letterSpacing: '-1.5px'
                        }}
                    >
                        Directory Node Explorer
                    </Title>
                    <div style={{ padding: '4px 16px', background: 'rgba(99, 102, 241, 0.05)', borderRadius: '24px', border: '1px solid rgba(99, 102, 241, 0.1)' }}>
                        <Text strong style={{ color: THEME.primary }}>{users?.length || 0} Registered Profiles</Text>
                    </div>
                </div>
                <Text
                    style={{
                        color: THEME.subtext,
                        fontSize: '16px',
                        fontWeight: 500,
                        fontFamily: "'DM Sans', sans-serif",
                        maxWidth: '750px',
                        display: 'block',
                        lineHeight: 1.6
                    }}
                >
                    Manage unified user identities across the Vacanza infrastructure. Review authentication status and privilege elevation for node administrators.
                </Text>
            </motion.div>

            <Row gutter={[24, 24]}>
                <Col xs={24} lg={16}>
                    <Card
                        bordered={false}
                        className="glass-card"
                        title={<span style={{ fontSize: 18, color: THEME.navy }}>Unified Identity Table</span>}
                        extra={
                            <Input
                                placeholder="Search by name or email..."
                                prefix={<SearchOutlined style={{ color: THEME.subtext }} />}
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                                style={{ width: 300, borderRadius: '12px' }}
                            />
                        }
                    >
                        <Table
                            columns={columns}
                            dataSource={filteredUsers}
                            loading={isLoading}
                            rowKey={(record) => record.user?.userId || record.user?.email}
                            pagination={{ pageSize: 8, showSizeChanger: false }}
                            style={{ overflow: 'hidden' }}
                        />
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card
                        className="glass-card"
                        variant="borderless"
                        title={<span style={{ fontSize: 18, color: THEME.navy }}>Quick Privilege Elevation</span>}
                        style={{ height: '100%' }}
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
                            padding: '20px',
                            background: 'rgba(114, 46, 209, 0.03)',
                            borderRadius: '16px',
                            border: '1px dashed rgba(114, 46, 209, 0.2)'
                        }}>
                            <Title level={5} style={{ fontSize: 12, color: THEME.admin, textTransform: 'uppercase', letterSpacing: 1, margin: '0 0 8px 0' }}>Authority Warning</Title>
                            <Text style={{ fontSize: 12, color: THEME.subtext, lineHeight: 1.5 }}>
                                Promoting a user to <b>ADMIN</b> grants full access to system monitoring, user directory, and global telemetry controls. This action is recorded in the system log.
                            </Text>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
