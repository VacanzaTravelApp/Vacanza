import React, { useState, useEffect, useCallback } from "react";
import { Table, Tag, Card, Row, Col, Progress, Badge, Typography, Space, Statistic, Spin, Empty, Tooltip as AntTooltip, Button } from "antd";
import {
    CheckCircleFilled,
    CloseCircleFilled,
    LoadingOutlined,
    ThunderboltOutlined,
    BlockOutlined,
    ApiOutlined,
    GlobalOutlined,
    DashboardOutlined,
    SyncOutlined,
    HistoryOutlined,
    DatabaseOutlined
} from "@ant-design/icons";
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import { motion, AnimatePresence } from "framer-motion";
import http from "../api/http";
import dayjs from "dayjs";

const { Title, Text } = Typography;

// Custom Gradient Colors (HSL based for vibrancy)
const THEME = {
    primary: 'hsl(250, 89%, 66%)',
    success: 'hsl(142, 70%, 45%)',
    warning: 'hsl(38, 92%, 50%)',
    error: 'hsl(0, 84%, 60%)',
    cardBg: 'rgba(255, 255, 255, 0.85)',
    darkBg: 'hsl(222, 47%, 11%)'
};

export default function Monitoring() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [chartData, setChartData] = useState([]);
    const [lastUpdated, setLastUpdated] = useState(new Date());

    const fetchMonitoringData = useCallback(async (isInitial = false) => {
        if (isInitial) setLoading(true);
        try {
            const response = await http.get("/admin/monitoring");
            const newData = response.data;
            setData(newData);
            setLastUpdated(new Date());

            // Build chart history
            setChartData(prev => {
                const metrics = newData.apiMetrics || newData.operationalStats || [];
                const avgLatency = metrics?.length > 0
                    ? metrics.reduce((acc, curr) => acc + (curr.avgResponseMs || 0), 0) / metrics.length
                    : 0;
                const newPoint = {
                    time: new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                    latency: Math.round(avgLatency),
                    health: (newData.systemHealth || 0) * 100
                };
                return [...prev, newPoint].slice(-24);
            });

            setError(null);
        } catch (err) {
            console.error("Monitoring fetch error:", err);
            setError("Connectivity issue with telemetry engine.");
        } finally {
            if (isInitial) setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchMonitoringData(true);
        const interval = setInterval(() => fetchMonitoringData(), 60000);
        return () => clearInterval(interval);
    }, [fetchMonitoringData]);

    const serviceColumns = [
        {
            title: "Provider Node",
            dataIndex: "name",
            key: "name",
            render: (text) => (
                <Space>
                    <div className="status-pulse-up" style={{ display: 'none' }} />
                    <DatabaseOutlined style={{ color: THEME.primary, opacity: 0.8 }} />
                    <Text strong style={{ fontSize: '14px' }}>{text}</Text>
                </Space>
            )
        },
        {
            title: "Operational Status",
            dataIndex: "status",
            key: "status",
            render: (status) => {
                const isUp = status === "UP" || status === "Active";
                return (
                    <Tag
                        bordered={false}
                        style={{
                            borderRadius: '20px',
                            padding: '4px 12px',
                            background: isUp ? 'hsla(142, 70%, 45%, 0.1)' : 'hsla(0, 84%, 60%, 0.1)',
                            color: isUp ? THEME.success : THEME.error,
                            border: `1px solid ${isUp ? 'hsla(142, 70%, 45%, 0.2)' : 'hsla(0, 84%, 60%, 0.2)'}`
                        }}
                        icon={isUp ? <CheckCircleFilled /> : <CloseCircleFilled />}
                    >
                        {status?.toUpperCase() || "UNKNOWN"}
                    </Tag>
                );
            },
        }
    ];

    const metricColumns = [
        { title: "Metric Key", dataIndex: "name", key: "name", render: (t) => <code style={{ color: THEME.primary, background: 'rgba(99, 102, 241, 0.05)', padding: '2px 6px', borderRadius: '4px' }}>{t}</code> },
        { title: "Total Calls", dataIndex: "totalCalls", key: "totalCalls", align: 'center', render: (val) => <Text strong>{val?.toLocaleString() || 0}</Text> },
        {
            title: "Error Ratio",
            dataIndex: "errorCount",
            key: "errorCount",
            render: (count, record) => {
                const ratio = ((count / (record.totalCalls || 1)) * 100).toFixed(1);
                return (
                    <Space direction="vertical" size={0}>
                        <Text type={count > 0 ? "danger" : "secondary"}>{count} ({ratio}%)</Text>
                        {record.consecutiveErrors > 0 && (
                            <AntTooltip title={`${record.consecutiveErrors} consecutive blocks`}>
                                <Text code type="danger" style={{ fontSize: 10 }}>STRIKE: {record.consecutiveErrors}</Text>
                            </AntTooltip>
                        )}
                    </Space>
                );
            }
        },
        {
            title: "Performance",
            dataIndex: "avgResponseMs",
            key: "avgResponseMs",
            render: (ms) => (
                <div style={{ minWidth: 100 }}>
                    <Text size="small" type={ms > 600 ? "danger" : ms > 300 ? "warning" : "secondary"}>{ms}ms</Text>
                    <Progress percent={Math.min(100, (ms / 1000) * 100)} showInfo={false} size={4} strokeColor={ms > 600 ? THEME.error : ms > 300 ? THEME.warning : THEME.primary} />
                </div>
            )
        },
    ];

    if (loading) return (
        <div style={{ minHeight: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center', background: '#f8fafc' }}>
            <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}>
                <Spin indicator={<LoadingOutlined style={{ fontSize: 60, color: THEME.primary }} spin />} />
                <div style={{ marginTop: 24, textAlign: 'center' }}>
                    <Title level={4} className="gradient-text">Syncing System Matrix</Title>
                    <Text type="secondary">Establishing secure administrative tunnel...</Text>
                </div>
            </motion.div>
        </div>
    );

    if (error) return (
        <div style={{ padding: 40, textAlign: 'center' }}>
            <Empty description={error} image={Empty.PRESENTED_IMAGE_SIMPLE}>
                <Button type="primary" onClick={() => fetchMonitoringData(true)}>Retry Connection</Button>
            </Empty>
        </div>
    );

    return (
        <div className="dashboard-container" style={{ paddingTop: '12px' }}>
            {/* Header Area */}
            <motion.div
                initial={{ y: -20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 16 }}
            >
                <Space size={16}>
                    <div style={{
                        width: 48, height: 48, borderRadius: '12px', background: THEME.primary,
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                        boxShadow: '0 8px 16px -4px rgba(99, 102, 241, 0.4)'
                    }}>
                        <ThunderboltOutlined style={{ fontSize: 24, color: 'white' }} />
                    </div>
                    <div>
                        <Title level={2} style={{ margin: 0, letterSpacing: -0.8 }}>System Health Engine</Title>
                        <Text type="secondary">Core Services & External API Telemetry</Text>
                    </div>
                </Space>
                <div style={{ textAlign: 'right' }}>
                    <Space direction="vertical" align="end" size={4}>
                        <Space split={<Badge status="processing" />} style={{ background: 'white', padding: '8px 16px', borderRadius: '12px', boxShadow: '0 2px 4px rgba(0,0,0,0.02)' }}>
                            <Text strong style={{ fontSize: 13 }}>LIVE RELAY</Text>
                            <Text type="secondary" style={{ fontSize: 12 }}>Last Pulse: {lastUpdated.toLocaleTimeString()}</Text>
                        </Space>
                        <Space size={4}>
                            <HistoryOutlined style={{ fontSize: 10, color: '#94a3b8' }} />
                            <Text type="secondary" style={{ fontSize: 10.5, letterSpacing: 0.2 }}>Active Intel Engine • v1.0.0-PROD</Text>
                        </Space>
                    </Space>
                </div>
            </motion.div>

            {/* Top Cards */}
            <Row gutter={[20, 20]}>
                <Col xs={24} lg={6}>
                    <motion.div whileHover={{ y: -5 }}>
                        <Card className="glass-card" bordered={false} bodyStyle={{ padding: '24px', textAlign: 'center' }}>
                            <Statistic
                                title={<Text type="secondary" style={{ textTransform: 'uppercase', fontSize: 12, letterSpacing: 1 }}>Overall Stability</Text>}
                                value={data?.systemHealth * 100}
                                precision={1}
                                suffix="%"
                                valueStyle={{ fontWeight: 800, fontSize: 32, color: THEME.primary }}
                                prefix={<DashboardOutlined style={{ marginRight: 8 }} />}
                            />
                            <div style={{ margin: '24px 0' }}>
                                <Progress
                                    type="dashboard"
                                    percent={Math.round(data?.systemHealth * 100)}
                                    strokeWidth={10}
                                    gapDegree={60}
                                    strokeColor={{ '0%': THEME.error, '50%': THEME.warning, '100%': THEME.success }}
                                    format={() => (
                                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                                            <span style={{ fontSize: 20, color: THEME.primary }}>{Math.round(data?.systemHealth * 100)}</span>
                                            <span style={{ fontSize: 10, color: '#999' }}>STABLE</span>
                                        </div>
                                    )}
                                />
                            </div>
                            <Text type="secondary" style={{ fontSize: 12 }}>
                                <Badge status={data?.systemHealth > 0.9 ? "success" : "warning"} text={data?.systemHealth > 0.9 ? "All nodes optimized" : "Warning: degraded performance"} />
                            </Text>
                        </Card>
                    </motion.div>
                </Col>
                <Col xs={24} lg={18}>
                    <Card
                        title={<Space><SyncOutlined spin={false} style={{ color: THEME.primary }} /> Latency & Performance History</Space>}
                        className="glass-card"
                        bordered={false}
                        extra={<Tag color="processing" style={{ borderRadius: 4 }}>Real-time Feed</Tag>}
                    >
                        <div style={{ height: 280, width: '100%', minHeight: 280 }}>
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={chartData}>
                                    <defs>
                                        <linearGradient id="latencyGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor={THEME.primary} stopOpacity={0.2} />
                                            <stop offset="95%" stopColor={THEME.primary} stopOpacity={0} />
                                        </linearGradient>
                                        <linearGradient id="healthGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor={THEME.success} stopOpacity={0.1} />
                                            <stop offset="95%" stopColor={THEME.success} stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(241, 245, 249, 1)" />
                                    <XAxis dataKey="time" hide />
                                    <YAxis axisLine={false} tickLine={false} style={{ fontSize: 11 }} />
                                    <Tooltip
                                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                                    />
                                    <Area
                                        type="monotone"
                                        dataKey="latency"
                                        stroke={THEME.primary}
                                        fillOpacity={1}
                                        fill="url(#latencyGrad)"
                                        strokeWidth={3}
                                        name="Response (ms)"
                                        animationDuration={1500}
                                    />
                                    <Area
                                        type="monotone"
                                        dataKey="health"
                                        stroke={THEME.success}
                                        strokeDasharray="5 5"
                                        fillOpacity={0.1}
                                        fill="url(#healthGrad)"
                                        strokeWidth={2}
                                        name="Health Index"
                                    />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Tables */}
            <Row gutter={[20, 20]} style={{ marginTop: 24 }}>
                <Col xs={24} lg={9}>
                    <Card
                        title={<Space><GlobalOutlined style={{ color: THEME.primary }} /> Runtime Node Index</Space>}
                        className="glass-card"
                        bordered={false}
                        styles={{ body: { padding: 0 } }}
                    >
                        <Table
                            dataSource={data?.services || data?.nodes || []}
                            columns={serviceColumns}
                            pagination={false}
                            size="middle"
                            rowKey={(record) => record.name || Math.random()}
                            scroll={{ y: 400 }}
                            className="custom-table"
                        />
                    </Card>
                </Col>
                <Col xs={24} lg={15}>
                    <Card
                        title={<Space><DatabaseOutlined style={{ color: THEME.primary }} /> Granular API Performance</Space>}
                        className="glass-card"
                        bordered={false}
                        styles={{ body: { padding: 0 } }}
                    >
                        <Table
                            dataSource={data?.apiMetrics || data?.operationalStats || []}
                            columns={metricColumns}
                            pagination={false}
                            size="middle"
                            rowKey={(record) => record.name || Math.random()}
                            scroll={{ y: 400 }}
                        />
                    </Card>
                </Col>
            </Row>

            {/* Unified Terminal Logs */}
            <Row style={{ marginTop: 24 }}>
                <Col span={24}>
                    <Card
                        title={<Space><BlockOutlined style={{ color: THEME.primary }} /> Unified Debugger Console</Space>}
                        className="glass-card"
                        bordered={false}
                        styles={{ body: { background: THEME.darkBg, padding: '0px', overflow: 'hidden', borderRadius: '0 0 16px 16px' } }}
                        extra={<Text style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>vacanza-admin@matrix:~$ view --live stdout</Text>}
                    >
                        <div style={{
                            height: 320,
                            overflowY: 'auto',
                            padding: '20px',
                            background: THEME.darkBg,
                            color: '#d1d5db',
                            fontSize: '12.5px'
                        }} className="terminal-font">
                            <AnimatePresence mode="popLayout">
                                {data?.logs?.length > 0 ? data.logs.map((log, idx) => (
                                    <motion.div
                                        key={`${log.timestamp}-${idx}`}
                                        initial={{ opacity: 0, x: -10 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        style={{ marginBottom: 6, lineHeight: 1.6, display: 'flex', gap: 16 }}
                                    >
                                        <span style={{ color: 'rgba(255,255,255,0.2)', minWidth: 150 }}>
                                            {dayjs(log.timestamp).format('HH:mm:ss.SSS')}
                                        </span>
                                        <span style={{
                                            color: log.level === 'ERROR' ? THEME.error :
                                                log.level === 'WARN' ? THEME.warning : THEME.success,
                                            fontWeight: 600,
                                            minWidth: 60
                                        }}>[{log.level}]</span>
                                        <span style={{ color: '#9ca3af' }}>{log.message}</span>
                                    </motion.div>
                                )) : (
                                    <div style={{ opacity: 0.3, textAlign: 'center', marginTop: 120 }}>
                                        <LoadingOutlined /> Awaiting system events...
                                    </div>
                                )}
                            </AnimatePresence>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
