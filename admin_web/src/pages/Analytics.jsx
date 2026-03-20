import React, { useState } from "react";
import {
    Card, Row, Col, Statistic, Table, Button, Space, Progress, DatePicker, Select, Typography, Badge, Tabs
} from "antd";
import {
    DownloadOutlined,
    ArrowUpOutlined,
    ArrowDownOutlined,
    GlobalOutlined,
    TeamOutlined,
    EnvironmentOutlined,
    PlayCircleOutlined,
    CalendarOutlined,
    FileSearchOutlined
} from "@ant-design/icons";
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts';
import { motion } from "framer-motion";

const { Title, Text, Paragraph } = Typography;
const { RangePicker } = DatePicker;

const userData = [
    { name: 'Jan', users: 4000 },
    { name: 'Feb', users: 3000 },
    { name: 'Mar', users: 2000 },
    { name: 'Apr', users: 2780 },
    { name: 'May', users: 1890 },
    { name: 'Jun', users: 2390 },
    { name: 'Jul', users: 3490 },
];

const categoryData = [
    { name: 'History', value: 400 },
    { name: 'Nature', value: 300 },
    { name: 'Culture', value: 300 },
    { name: 'Modern', value: 200 },
];

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

const topPois = [
    { key: '1', name: "Topkapı Sarayı", category: "History", checkins: 1240, rating: 4.8 },
    { key: '2', name: "Galata Kulesi", category: "Sightseeing", checkins: 2150, rating: 4.9 },
    { key: '3', name: "Antalya Beach", category: "Nature", checkins: 890, rating: 4.5 },
    { key: '4', name: "Sümela Manastırı", category: "History", checkins: 670, rating: 4.2 },
];

export default function Analytics() {
    const [loading, setLoading] = useState(false);

    const handleGenerate = () => {
        setLoading(true);
        setTimeout(() => {
            setLoading(false);
            message.success("Report generated successfully!");
        }, 1500);
    };

    const columns = [
        { title: "Point of Interest", dataIndex: "name", key: "name", render: (text) => <strong>{text}</strong> },
        { title: "Category", dataIndex: "category", key: "category", render: (text) => <Tag color="blue">{text}</Tag> },
        { title: "Total Check-ins", dataIndex: "checkins", key: "checkins", sorter: (a, b) => a.checkins - b.checkins },
        { title: "Rating", dataIndex: "rating", key: "rating", render: (r) => <span style={{ color: '#faad14' }}>{r} ⭐</span> },
    ];

    return (
        <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
            style={{ padding: "12px" }}
        >
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "20px", alignItems: 'center' }}>
                <Title level={2} style={{ margin: 0 }}>Generate Analytics Report (UC2.2)</Title>
                <Space>
                    <RangePicker />
                    <Button type="primary" icon={<PlayCircleOutlined />} onClick={handleGenerate} loading={loading}>Generate</Button>
                    <Button icon={<DownloadOutlined />}>Export CSV</Button>
                </Space>
            </div>

            <Row gutter={[16, 16]}>
                <Col span={6}>
                    <Card variant="borderless" styles={{ body: { padding: '20px' } }}>
                        <Statistic title="Total Registered Users" value={112893} precision={0} styles={{ content: { color: "#3f8600" } }} prefix={<TeamOutlined />} />
                        <Text type="secondary" size="small"><ArrowUpOutlined /> 12% from last month</Text>
                    </Card>
                </Col>
                <Col span={6}>
                    <Card variant="borderless" styles={{ body: { padding: '20px' } }}>
                        <Statistic title="Monthly Revenue" value={45210} precision={2} styles={{ content: { color: "#1677ff" } }} prefix="$" />
                        <Text type="secondary" size="small"><ArrowUpOutlined /> 5% from last month</Text>
                    </Card>
                </Col>
                <Col span={6}>
                    <Card variant="borderless" styles={{ body: { padding: '20px' } }}>
                        <Statistic title="Active POIs" value={842} precision={0} styles={{ content: { color: "#faad14" } }} prefix={<EnvironmentOutlined />} />
                        <Text type="secondary" size="small"><ArrowDownOutlined /> 2% from last month</Text>
                    </Card>
                </Col>
                <Col span={6}>
                    <Card variant="borderless" styles={{ body: { padding: '20px' } }}>
                        <Statistic title="Avg. Visit Time" value={2.4} precision={1} styles={{ content: { color: "#722ed1" } }} prefix={<CalendarOutlined />} suffix="hrs" />
                        <Text type="secondary" size="small"><ArrowUpOutlined /> 8% from last month</Text>
                    </Card>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: "24px" }}>
                <Col span={16}>
                    <Card
                        title={<Space><FileSearchOutlined /> Growth Trends</Space>}
                        variant="borderless"
                        styles={{ body: { height: 400 } }}
                    >
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={userData}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} />
                                <YAxis axisLine={false} tickLine={false} />
                                <Tooltip cursor={{ fill: '#f5f5f5' }} />
                                <Bar dataKey="users" fill="#1677ff" radius={[4, 4, 0, 0]} barSize={40} />
                            </BarChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
                <Col span={8}>
                    <Card
                        title={<Space><GlobalOutlined /> POI Category Distribution</Space>}
                        variant="borderless"
                        styles={{ body: { height: 400 } }}
                    >
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={categoryData}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={100}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {categoryData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend layout="horizontal" verticalAlign="bottom" align="center" />
                            </PieChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: "24px" }}>
                <Col span={24}>
                    <Card title="Detailed Performance Data" variant="borderless">
                        <Table dataSource={topPois} columns={columns} pagination={false} size="middle" />
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
