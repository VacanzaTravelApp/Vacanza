import React, { useState } from "react";
import { Tag, Card, Row, Col, Statistic, Table, Button, Space, Progress, DatePicker, Typography, Badge, Avatar, message, Empty } from "antd";
import {
    DownloadOutlined,
    ArrowUpOutlined,
    GlobalOutlined,
    TeamOutlined,
    PlayCircleOutlined,
    CalendarOutlined,
    FileSearchOutlined,
    ClockCircleOutlined,
    CheckCircleOutlined
} from "@ant-design/icons";
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts';
import { motion } from "framer-motion";
import { MdFlightTakeoff } from "react-icons/md";
import { adminApi } from "../api/userApi";
import { useQuery } from "@tanstack/react-query";

const { Title, Text, Paragraph } = Typography;
const { RangePicker } = DatePicker;

const COLORS = ['#1677ff', '#52c41a', '#faad14', '#13c2c2', '#722ed1', '#eb2f96'];

/**
 * FReq13 – Administrative Insight and Monitoring Dashboard.
 * Focuses on summarized usage statistics, registration trends, and platform engagement.
 */
export default function Analytics() {
    const [dateRange, setDateRange] = useState([]);

    const { data: analytics, isLoading, isFetching, refetch } = useQuery({
        queryKey: ["admin-analytics", dateRange],
        queryFn: async () => {
            const params = {};
            if (dateRange && dateRange.length === 2) {
                params.startDate = dateRange[0].toISOString();
                params.endDate = dateRange[1].toISOString();
            }
            const res = await adminApi.getAnalytics(params);
            return res.data;
        }
    });

    const handleSync = () => {
        refetch();
    };

    return (
        <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
            style={{ padding: "12px" }}
        >
            <div style={{
                display: "flex",
                justifyContent: "space-between",
                marginBottom: "24px",
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '12px'
            }}>
                <div>
                    <Title level={2} style={{ margin: 0 }}>Operational Insights (FReq13)</Title>
                    <Text type="secondary">Summarized system usage and user engagement metrics.</Text>
                </div>
                <Space wrap>
                    <RangePicker
                        onChange={(val) => setDateRange(val)}
                        style={{ height: 40 }}
                    />
                    <Button
                        type="primary"
                        size="large"
                        icon={<MdFlightTakeoff />}
                        onClick={handleSync}
                        loading={isFetching}
                    >
                        Sync Data
                    </Button>
                    <Button size="large" icon={<DownloadOutlined />}>Log CSV</Button>
                </Space>
            </div>

            <Row gutter={[16, 16]}>
                <Col xs={24} sm={12} lg={8}>
                    <Card variant="borderless" style={{ borderRadius: 12 }}>
                        <Statistic
                            title="Total System Users"
                            value={analytics?.totalUsers || 0}
                            precision={0}
                            valueStyle={{ color: "#3f8600" }}
                            prefix={<TeamOutlined />}
                        />
                        <Text type="secondary" size="small"><ArrowUpOutlined /> Cumulative Total</Text>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={8}>
                    <Card variant="borderless" style={{ borderRadius: 12 }}>
                        <Statistic
                            title="Active Sessions (FReq13)"
                            value={analytics?.activeSessions || 0}
                            precision={0}
                            valueStyle={{ color: "#1677ff" }}
                            prefix={<ClockCircleOutlined />}
                        />
                        <Text type="secondary" size="small">Concurrent users globally</Text>
                    </Card>
                </Col>
                <Col xs={24} sm={24} lg={8}>
                    <Card variant="borderless" style={{ borderRadius: 12 }}>
                        <Statistic
                            title="Platform Status"
                            value={100}
                            suffix="%"
                            precision={0}
                            valueStyle={{ color: "#52c41a" }}
                            prefix={<CheckCircleOutlined />}
                        />
                        <Text type="secondary" size="small">All services operational</Text>
                    </Card>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: "24px" }}>
                <Col xs={24} lg={16}>
                    <Card
                        title={<Space><FileSearchOutlined /> User Acquisition Trends</Space>}
                        variant="borderless"
                        styles={{ body: { height: 400 } }}
                        loading={isLoading}
                        style={{ borderRadius: 12 }}
                    >
                        {(!analytics?.growthTrends || analytics.growthTrends.length === 0) ? (
                            <Empty description="Waiting for system logs aggregation..." />
                        ) : (
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={analytics?.growthTrends}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                                    <XAxis dataKey="period" axisLine={false} tickLine={false} />
                                    <YAxis axisLine={false} tickLine={false} />
                                    <Tooltip cursor={{ fill: '#fafafa' }} />
                                    <Bar dataKey="newUsers" fill="#1677ff" radius={[6, 6, 0, 0]} barSize={40} />
                                </BarChart>
                            </ResponsiveContainer>
                        )}
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card
                        title={<Space><GlobalOutlined /> POI Category Distribution</Space>}
                        variant="borderless"
                        styles={{ body: { height: 400 } }}
                        loading={isLoading}
                        style={{ borderRadius: 12 }}
                    >
                        {(!analytics?.categoryDistribution || analytics.categoryDistribution.length === 0) ? (
                            <Empty description="No check-in category data yet..." />
                        ) : (
                            <div style={{ height: '300px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                                <ResponsiveContainer width="100%" height={250}>
                                    <PieChart>
                                        <Pie
                                            data={analytics.categoryDistribution.map(cat => ({ name: cat.category, value: cat.count }))}
                                            cx="50%"
                                            cy="50%"
                                            innerRadius={60}
                                            outerRadius={80}
                                            dataKey="value"
                                        >
                                            {analytics.categoryDistribution.map((entry, index) => (
                                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                            ))}
                                        </Pie>
                                        <Tooltip />
                                        <Legend verticalAlign="bottom" height={36} />
                                    </PieChart>
                                </ResponsiveContainer>
                            </div>
                        )}
                    </Card>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: "24px" }}>
                <Col xs={24}>
                    <Card
                        title={<Space><FileSearchOutlined /> Top Visited POIs</Space>}
                        variant="borderless"
                        style={{ borderRadius: 12 }}
                        loading={isLoading}
                    >
                        <Table
                            dataSource={analytics?.topPois || []}
                            pagination={false}
                            rowKey="name"
                            size="small"
                            columns={[
                                { title: 'POI Name', dataIndex: 'name', key: 'name', render: text => <strong>{text}</strong> },
                                { title: 'Category', dataIndex: 'category', key: 'category', render: text => <Tag color="geekblue">{text}</Tag> },
                                { title: 'Total Visits (Check-ins)', dataIndex: 'visitCount', key: 'visitCount', render: val => <Badge count={val} color="#52c41a" /> }
                            ]}
                        />
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
