import React from "react";
import { Table, Tag, Card, Button, Input, Space, Typography, message } from "antd";
const { Text } = Typography;
import { SearchOutlined, UserOutlined, EditOutlined, DeleteOutlined } from "@ant-design/icons";
import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";

export default function UserManagement() {
    const { data: users, isLoading } = useQuery({
        queryKey: ["all-users"],
        queryFn: async () => {
            const res = await userApi.getAllUsers();
            // res.data is expected to be List<UserLoginResponseDTO>
            return res.data;
        },
    });

    const columns = [
        {
            title: "User ID",
            dataIndex: ["user", "userId"],
            key: "userId",
            ellipsis: true,
        },
        {
            title: "Display Name",
            dataIndex: ["user", "displayName"],
            key: "displayName",
            render: (text) => <a>{text || "N/A"}</a>,
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
            render: (role) => <Tag color={role === "ADMIN" ? "gold" : "blue"}>{role}</Tag>
        },
        {
            title: "Registered Date",
            dataIndex: ["user", "createdAt"],
            key: "createdAt",
            render: (date) => (
                <Text type="secondary" style={{ fontSize: '13px' }}>
                    {date ? new Date(date).toLocaleDateString() : "N/A"}
                </Text>
            )
        },
        {
            title: "Authenticated",
            dataIndex: "authenticated",
            key: "authenticated",
            render: (auth) => (
                <Tag color={auth ? "green" : "volcano"}>
                    {auth ? "YES" : "NO"}
                </Tag>
            )
        },
        {
            title: "Actions",
            key: "actions",
            render: (_, record) => (
                <Space size="middle">
                    <Button icon={<EditOutlined />} size="small" />
                    <Button icon={<DeleteOutlined />} danger size="small" />
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: "12px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "20px", alignItems: "center" }}>
                <h2>User Management</h2>
                <Input
                    prefix={<SearchOutlined />}
                    placeholder="Search users..."
                    style={{ width: "300px" }}
                />
            </div>

            <Card variant="borderless" styles={{ body: { padding: 0 } }}>
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
