import React from "react";
import { Table, Tag, Card, Button, Input, Space, message } from "antd";
import { SearchOutlined, UserOutlined, EditOutlined, DeleteOutlined } from "@ant-design/icons";
import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";

export default function UserManagement() {
    const { data: users, isLoading, refetch } = useQuery({
        queryKey: ["all-users"],
        queryFn: async () => {
            const res = await userApi.getAllUsers();
            return res.data;
        },
    });

    const handlePromote = async (email) => {
        try {
            message.loading({ content: "Promoting user...", key: "promote" });
            await userApi.promoteUserToAdmin(email);
            message.success({ content: "User promoted to ADMIN successfully!", key: "promote" });
            refetch(); // Tabloyu tazele
        } catch (error) {
            console.error("Promotion failed", error);
            message.error({ content: "Failed to promote user. Check permissions.", key: "promote" });
        }
    };

    const columns = [
        {
            title: "Display Name",
            dataIndex: ["user", "displayName"],
            key: "displayName",
            render: (text) => <b>{text || "User"}</b>,
        },
        {
            title: "Email",
            dataIndex: ["user", "email"],
            key: "email",
        },
        {
            title: "Role",
            dataIndex: ["user", "role"],
            key: "role",
            render: (role) => (
                <Tag color={role === "ADMIN" ? "purple" : "blue"} style={{ borderRadius: '6px', padding: '2px 8px' }}>
                    {role || "USER"}
                </Tag>
            )
        },
        {
            title: "Authenticated",
            dataIndex: "authenticated",
            key: "authenticated",
            render: (auth) => (
                <Tag color={auth ? "green" : "volcano"} style={{ borderRadius: '6px' }}>
                    {auth ? "YES" : "NO"}
                </Tag>
            )
        },
        {
            title: "Actions",
            key: "actions",
            render: (_, record) => (
                <Space size="middle">
                    {record.user?.role !== "ADMIN" ? (
                        <Button
                            type="primary"
                            size="small"
                            onClick={() => handlePromote(record.user?.email)}
                            style={{ backgroundColor: '#722ed1', borderColor: '#722ed1' }}
                        >
                            Make Admin
                        </Button>
                    ) : (
                        <Tag color="default">Already Admin</Tag>
                    )}
                    <Button icon={<DeleteOutlined />} danger size="small" />
                </Space>
            ),
        },
    ];

    const [manualEmail, setManualEmail] = React.useState("");

    return (
        <div style={{ padding: "12px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "20px", alignItems: "center" }}>
                <h2 style={{ fontSize: '28px', fontWeight: 600 }}>User Management</h2>
                <Input
                    prefix={<SearchOutlined />}
                    placeholder="Search users in table..."
                    style={{ width: "300px", borderRadius: '8px' }}
                />
            </div>

            {/* Manual Promotion Panel */}
            <Card
                title={<span style={{ color: '#1a1a1a' }}>Manual Admin Promotion</span>}
                style={{ marginBottom: '24px', borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
            >
                <Space.Compact style={{ width: '100%', maxWidth: '500px' }}>
                    <Input
                        placeholder="Enter user email to promote..."
                        value={manualEmail}
                        onChange={(e) => setManualEmail(e.target.value)}
                        prefix={<UserOutlined style={{ color: '#bfbfbf' }} />}
                    />
                    <Button
                        type="primary"
                        onClick={() => {
                            if (!manualEmail) return message.warning("Please enter an email!");
                            handlePromote(manualEmail);
                            setManualEmail("");
                        }}
                        style={{ backgroundColor: '#722ed1', borderColor: '#722ed1' }}
                    >
                        Make Admin
                    </Button>
                </Space.Compact>
                <p style={{ marginTop: '8px', color: '#8c8c8c', fontSize: '13px' }}>
                    Note: This will grant full administrative privileges to the specified email in the database.
                </p>
            </Card>

            <Card variant="borderless" styles={{ body: { padding: 0 } }} style={{ borderRadius: '12px', overflow: 'hidden', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}>
                <Table
                    columns={columns}
                    dataSource={users}
                    loading={isLoading}
                    rowKey={(record) => record.user?.userId || record.user?.email || Math.random()}
                    pagination={{ pageSize: 10, showSizeChanger: true }}
                    style={{ overflow: 'hidden', borderRadius: '12px' }}
                />
            </Card>
        </div>
    );
}
