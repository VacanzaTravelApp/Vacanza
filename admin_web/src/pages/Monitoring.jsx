import React from "react";
import { Row, Col, Card, Typography, Tag, Space, Spin, Badge, Progress } from "antd";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip } from "recharts";
import { LoadingOutlined, CloudServerOutlined, BugFilled, CheckCircleFilled, WarningFilled } from "@ant-design/icons";
import useFetch from "../hooks/useFetch";
import { motion } from "framer-motion";
import dayjs from "dayjs";

const { Title, Text } = Typography;

const THEME = {
    primary: '#FF6B6B',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    cardBg: 'rgba(255, 255, 255, 0.85)',
    darkBg: '#1A2332'
};

const Monitoring = () => {
    const { data, loading } = useFetch('/admin/monitoring');

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
        { title: "Metric Key", dataIndex: "apiName", key: "apiName", render: (t) => <code style={{ color: THEME.primary, background: 'rgba(99, 102, 241, 0.05)', padding: '2px 6px', borderRadius: '4px' }}>{t || 'Unknown'}</code> },
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
        <div className="dashboard-container">
            <Row gutter={[48, 48]}>
                <Col span={24}>
                    <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                        <Title level={4} style={{ color: THEME.coral, marginBottom: 8, letterSpacing: 2, textTransform: 'uppercase', fontSize: 13, fontWeight: 700 }}>
                            INFRASTRUCTURE OVERWATCH
                        </Title>
                        <Title className="gradient-text" style={{ fontSize: '56px', margin: '0 0 16px 0', lineHeight: 1.1, letterSpacing: '-1.5px' }}>
                            System Matrix
                        </Title>
                        <Text style={{ fontSize: '18px', color: THEME.subtext, fontWeight: 500 }}>Global telemetry, service node health, and live execution tracing.</Text>
                    </motion.div>
                </Col>

                <Col xs={24} lg={16}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>API Performance Index</span>}>
                        <div style={{ height: 350, width: '100%', marginTop: 24 }}>
                            <ResponsiveContainer>
                                <LineChart data={data?.apiMetrics || []}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(26, 35, 50, 0.05)" />
                                    <XAxis dataKey="apiName" hide />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <Tooltip
                                        labelStyle={{ color: THEME.navy, fontWeight: 700 }}
                                        contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.1)', padding: '16px' }}
                                    />
                                    <Line name="Avg Response (ms)" type="monotone" dataKey="avgResponseMs" stroke={THEME.coral} strokeWidth={4} dot={false} activeDot={{ r: 8, fill: THEME.coral, stroke: 'white', strokeWidth: 3 }} />
                                    <Line name="Total Calls" type="monotone" dataKey="totalCalls" stroke={THEME.teal} strokeWidth={2} dot={false} strokeDasharray="5 5" />
                                </LineChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>

                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>Service Node Topography</span>} style={{ marginTop: 48 }}>
                        <Row gutter={[24, 24]}>
                            {(data?.services || []).map((service, idx) => (
                                <Col xs={24} sm={12} key={idx}>
                                    <div style={{
                                        padding: '28px',
                                        background: 'rgba(26, 35, 50, 0.03)',
                                        borderRadius: '24px',
                                        border: '1px solid rgba(26, 35, 50, 0.06)',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        gap: 16
                                    }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Space size={12}>
                                                <CloudServerOutlined style={{ fontSize: 22, color: THEME.navy }} />
                                                <Text strong style={{ fontSize: 17, color: THEME.navy }}>{service.name}</Text>
                                            </Space>
                                            <Tag color={service.status === 'UP' ? 'success' : 'error'} bordered={false} style={{ borderRadius: 8, fontWeight: 800 }}>{service.status}</Tag>
                                        </div>

                                    </div>
                                </Col>
                            ))}
                        </Row>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>System Telemetry</span>}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
                            <div style={{ padding: '32px', background: 'rgba(26, 35, 50, 0.04)', borderRadius: '24px' }}>
                                <Text style={{ fontSize: 12, color: THEME.subtext, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 12 }}>Infrastructure Health</Text>
                                <Title level={1} style={{ margin: '0 0 12px 0', color: THEME.navy, fontWeight: 800, fontSize: 48 }}>{Math.round((data?.systemHealth || 0) * 100)}%</Title>
                                <Progress percent={Math.round((data?.systemHealth || 0) * 100)} strokeColor={THEME.green} status="active" strokeWidth={12} />
                            </div>

                            <div style={{ padding: '32px', background: `${THEME.navy}`, borderRadius: '24px', color: 'white' }}>
                                <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 12 }}>Metric Density</Text>
                                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12 }}>
                                    <Title level={1} style={{ margin: 0, color: 'white', fontWeight: 800, fontSize: 48 }}>{data?.apiMetrics?.length || 0}</Title>
                                    <Text style={{ color: THEME.green, fontWeight: 800, paddingBottom: 10 }}>ACTIVE STREAMS</Text>
                                </div>
                            </div>
                        </div>

                        <div style={{
                            marginTop: 48,
                            background: '#06080b',
                            borderRadius: '32px',
                            padding: '32px',
                            minHeight: 450,
                            boxShadow: '0 30px 60px rgba(0,0,0,0.4)',
                            border: '1px solid rgba(255,255,255,0.05)'
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                                <div style={{ display: 'flex', gap: 8 }}>
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f56' }} />
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#27c93f' }} />
                                </div>
                                <Tag bordered={false} style={{ margin: 0, background: 'rgba(45, 212, 168, 0.1)', color: THEME.green, fontWeight: 800, fontSize: 10 }}>LIVE_TRACE</Tag>
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                                {(data?.logs || []).map((log, idx) => (
                                    <div key={idx} style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', lineHeight: 1.6, display: 'flex' }}>
                                        <span style={{ color: THEME.green, opacity: 0.8, whiteSpace: 'nowrap' }}>[{dayjs(log.timestamp).format('HH:mm:ss')}]</span>
                                        <span style={{
                                            color: log.level === 'ERROR' ? THEME.coral : log.level === 'WARN' ? THEME.amber : '#5A6B7A',
                                            marginLeft: 12,
                                            fontWeight: 800,
                                            minWidth: 50
                                        }}>{log.level}</span>
                                        <span style={{ color: '#e2e8f0', marginLeft: 12 }}>{log.message}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default Monitoring;
