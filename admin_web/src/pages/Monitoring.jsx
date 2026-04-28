import React, { useState, useEffect, useCallback } from "react";
import { Row, Col, Card, Typography, Tag, Space, Spin, Badge, Progress, Table, Button, Empty, Tooltip as AntTooltip, Grid } from "antd";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from "recharts";
import { LoadingOutlined, DatabaseOutlined, CloudServerOutlined, BugFilled, CheckCircleFilled, WarningFilled, CopyOutlined, CheckCircleOutlined, SyncOutlined, CloseCircleFilled } from "@ant-design/icons";
import http from "../api/http";
import { motion } from "framer-motion";
import dayjs from "dayjs";

const { Title, Text } = Typography;
const { useBreakpoint } = Grid;

const THEME = {
    primary: '#FF6B6B',
    coral: '#FF6B6B',
    navy: '#1A2332',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    teal: '#00B4D8',
    subtext: '#5A6B7A',
    green: '#2DD4A8',
    amber: '#FFB347',
    cardBg: 'rgba(255, 255, 255, 0.85)',
    darkBg: '#1A2332'
};

const TerminalCommandBlock = ({ cmdString }) => {
    const [copied, setCopied] = useState(false);
    const handleCopy = () => {
        navigator.clipboard.writeText(cmdString);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };
    return (
        <div
            onClick={handleCopy}
            style={{
                background: '#06080b',
                color: THEME.green,
                fontFamily: 'var(--font-mono), monospace',
                padding: '10px 16px',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '12px',
                border: `1px solid ${THEME.green}33`,
                whiteSpace: 'normal',
                wordBreak: 'break-word',
                cursor: 'pointer',
                boxShadow: '0 4px 12px rgba(0,0,0,0.05)',
                width: '100%',
                transition: 'all 0.2s'
            }}
            onMouseOver={(e) => e.currentTarget.style.border = `1px solid ${THEME.green}`}
            onMouseOut={(e) => e.currentTarget.style.border = `1px solid ${THEME.green}33`}
        >
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
                <span style={{ color: '#5A6B7A', fontWeight: 800 }}>$</span>
                <span style={{ letterSpacing: '0.5px', fontSize: '12px' }}>{cmdString}</span>
            </div>
            {copied ? <CheckCircleOutlined style={{ color: THEME.success, fontSize: '14px' }} title="Copied!" /> : <CopyOutlined style={{ color: '#5A6B7A', fontSize: '14px' }} title="Copy command" />}
        </div>
    );
};

const Monitoring = () => {
    const screens = useBreakpoint();
    const isMobile = !screens.md;
    const isTablet = !!screens.md && !screens.lg;
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [chartData, setChartData] = useState([]);
    const [lastUpdated, setLastUpdated] = useState(new Date());
    const [realStatuses, setRealStatuses] = useState({});
    const [hasInitialScanRun, setHasInitialScanRun] = useState(false);

    const SERVICE_KEY_MAP = {
        "Currency Exchange (Frankfurter)": "frankfurter",
        "Weather Service (OpenMeteo)": "openmeteo",
        "Local Places (Foursquare)": "foursquare",
        "Maps & Geocoding (Mapbox)": "mapbox",
        "Hotel Search (SerpApi)": "serpapi",
        "Hotel & Flight Search (SerpApi)": "serpapi",
        "Events (Ticketmaster)": "ticketmaster",
        "Tours/Activities (Viator)": "viator",
        "AI Recommendation Engine": "ai",
    };

    const fetchMonitoringData = useCallback(async (isInitial = false) => {
        if (isInitial) setLoading(true);
        try {
            const response = await http.get("/admin/monitoring");
            let newData = response.data;

            // Merge with any real statuses we've discovered via actual PING triggers
            setRealStatuses(currentRealStatuses => {
                if (Object.keys(currentRealStatuses).length > 0) {
                    newData = {
                        ...newData,
                        services: newData.services.map(s => {
                            const key = SERVICE_KEY_MAP[s.name];
                            if (key && currentRealStatuses[key]) {
                                const st = typeof currentRealStatuses[key] === 'object' ? currentRealStatuses[key].status : currentRealStatuses[key];
                                const ms = typeof currentRealStatuses[key] === 'object' ? currentRealStatuses[key].ms : undefined;
                                return { ...s, status: st, responseMs: ms };
                            }
                            return s;
                        })
                    };
                }
                return currentRealStatuses;
            });

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
        // Refresh every 10 seconds for real-time accuracy
        const interval = setInterval(() => fetchMonitoringData(), 10000);
        return () => clearInterval(interval);
    }, [fetchMonitoringData]);

    const runAutomatedDiagnosticSweep = useCallback(async () => {
        if (hasInitialScanRun) return;
        setHasInitialScanRun(true);

        const testableKeys = Object.values(SERVICE_KEY_MAP);

        for (const serviceKey of testableKeys) {
            http.post(`/admin/health-check/${serviceKey}`)
                .then(res => {
                    const status = res.data?.status === "UP" ? "UP" : "DOWN";
                    setRealStatuses(prev => {
                        const next = { ...prev, [serviceKey]: { status: status, ms: res.data?.responseMs } };
                        // Force update data to reflect the new state immediately
                        setData(currentData => {
                            if (!currentData) return currentData;
                            return {
                                ...currentData,
                                services: currentData.services.map(s =>
                                    SERVICE_KEY_MAP[s.name] === serviceKey ? { ...s, status: status, responseMs: res.data?.responseMs } : s
                                )
                            };
                        });
                        return next;
                    });
                })
                .catch(err => {
                    setRealStatuses(prev => {
                        const ms = err.response?.data?.responseMs || 0;
                        const next = { ...prev, [serviceKey]: { status: "DOWN", ms } };
                        setData(currentData => {
                            if (!currentData) return currentData;
                            return {
                                ...currentData,
                                services: currentData.services.map(s =>
                                    SERVICE_KEY_MAP[s.name] === serviceKey ? { ...s, status: "DOWN", responseMs: ms } : s
                                )
                            };
                        });
                        return next;
                    });
                });
        }
    }, [hasInitialScanRun]);

    useEffect(() => {
        if (data && !hasInitialScanRun && !loading) {
            // Wait 1.5 seconds after table renders then sweep all to discover actual reality
            const timeout = setTimeout(() => {
                runAutomatedDiagnosticSweep();
            }, 1500);
            return () => clearTimeout(timeout);
        }
    }, [data, hasInitialScanRun, loading, runAutomatedDiagnosticSweep]);

    const HealthCheckButton = ({ serviceName }) => {
        const [state, setState] = useState("idle");
        const [result, setResult] = useState(null);

        const handleTest = async () => {
            setState("loading");
            try {
                const response = await http.post(`/admin/health-check/${serviceName}`);
                const dataResponse = response.data;
                setResult(dataResponse);
                const newStatus = dataResponse.status === "UP" ? "up" : "down";
                setState(newStatus);

                // Real-time synchronization with the main table
                if (setData) {
                    setRealStatuses(prevSt => ({ ...prevSt, [serviceName]: { status: newStatus === "up" ? "UP" : "DOWN", ms: dataResponse.responseMs } }));
                    setData(prev => ({
                        ...prev,
                        services: prev.services.map(s => {
                            return SERVICE_KEY_MAP[s.name] === serviceName
                                ? { ...s, status: dataResponse.status, responseMs: dataResponse.responseMs }
                                : s;
                        })
                    }));
                }

                setTimeout(() => setState("idle"), 5000);
            } catch (e) {
                const ms = e.response?.data?.responseMs || 0;
                setResult({ message: e.response?.data?.message || "Connection Error", responseMs: ms });
                setState("down");
                if (setData) {
                    setRealStatuses(prevSt => ({ ...prevSt, [serviceName]: { status: "DOWN", ms } }));
                    setData(prev => ({
                        ...prev,
                        services: prev.services.map(s => {
                            return SERVICE_KEY_MAP[s.name] === serviceName
                                ? { ...s, status: "DOWN", responseMs: ms }
                                : s;
                        })
                    }));
                }
                setTimeout(() => setState("idle"), 5000);
            }
        };

        const getLatencyStatus = (ms) => {
            if (ms < 500) return "Excellent (Perfectly fluid response)";
            if (ms < 2000) return "Normal (Stable connection)";
            return "Slow (High latency detected)";
        };

        const getLatencyColor = (ms) => {
            if (ms < 500) return THEME.green;
            if (ms < 2000) return "#FFB347"; // Warning color
            return THEME.error;
        };

        if (state === "loading") return <Button size="small" type="link" icon={<SyncOutlined spin />} disabled style={{ fontSize: 12 }}>Testing...</Button>;

        if (state === "up") return (
            <AntTooltip title={getLatencyStatus(result?.responseMs)}>
                <Tag color="success" icon={<CheckCircleFilled />} style={{ fontWeight: 700, borderRadius: '20px', cursor: 'help' }}>
                    UP (<span style={{ color: getLatencyColor(result?.responseMs) }}>{result?.responseMs}ms</span>)
                </Tag>
            </AntTooltip>
        );

        if (state === "down") return (
            <AntTooltip title={result?.message}>
                <Tag color="error" icon={<CloseCircleFilled />} style={{ cursor: 'help', borderRadius: '20px' }}>
                    DOWN <span style={{ opacity: 0.8 }}>({result?.responseMs || 0}ms)</span>
                </Tag>
            </AntTooltip>
        );

        return (
            <Button
                size="small"
                type="primary"
                ghost
                onClick={handleTest}
                style={{ borderRadius: '20px', fontSize: 11, height: 24, padding: '0 12px' }}
            >
                Test
            </Button>
        );
    };

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
            render: (status, record) => {
                const isUp = status === "UP" || status === "Active";
                return (
                    <Tag
                        variant="filled"
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
                        {record.responseMs !== undefined && <span style={{ marginLeft: 6, opacity: 0.85, fontSize: '0.9em' }}>({record.responseMs}ms)</span>}
                    </Tag>
                );
            },
        },
        {
            title: "Action",
            key: "action",
            align: 'right',
            render: (_, record) => {
                const serviceKey = SERVICE_KEY_MAP[record.name];
                if (!serviceKey) return <Text style={{ color: 'rgba(26, 35, 50, 0.2)', fontSize: 11, fontStyle: 'italic' }}>Internal Node</Text>;

                return <HealthCheckButton serviceName={serviceKey} />;
            }
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

    const activityCategoryMeta = {
        coreSystemOperations: {
            name: "System Actions",
            description: "Route planning, monitoring, and internal app actions"
        },
        contentAndLocationData: {
            name: "Travel & Map Data",
            description: "POI, map, destination, and trip data processing"
        },
        authenticationAndSecurityEvents: {
            name: "User & Security Activity",
            description: "Login, access control, and security-related actions"
        },
        userOperations: {
            name: "User Operations",
            description: "User account activity and profile-related processing"
        },
        dataIntelligence: {
            name: "Data Intelligence",
            description: "Analytics generation and reporting-related processing"
        }
    };

    const getActivityCategory = (apiName = "") => {
        if (apiName.includes('admin')) return activityCategoryMeta.coreSystemOperations;
        if (apiName.includes('auth')) return activityCategoryMeta.authenticationAndSecurityEvents;
        if (apiName.includes('user')) return activityCategoryMeta.userOperations;
        if (apiName.includes('analytics')) return activityCategoryMeta.dataIntelligence;
        return activityCategoryMeta.contentAndLocationData;
    };

    if (loading) return (
        <div style={{ height: '70vh', width: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
            <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                style={{ textAlign: 'center' }}
            >
                <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: THEME.primary, marginBottom: 24 }} spin />} description="SYSTEM MATRIX" />
                <div style={{ marginTop: 16 }}>
                    <Text type="secondary" style={{ fontSize: 16, letterSpacing: 1.5, textTransform: 'uppercase', fontWeight: 600, opacity: 0.7 }}>
                        Authenticating & Syncing Node Telemetry
                    </Text>
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
        <div className="dashboard-container" style={{ overflowX: 'hidden' }}>
            <Row gutter={[isMobile ? 24 : 48, isMobile ? 24 : 48]}>
                <Col span={24}>
                    <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                        <Title
                            className="gradient-text"
                            style={{
                                fontSize: '32px',
                                margin: '0 0 10px 0',
                                letterSpacing: '-1.2px',
                                fontFamily: "'Fraunces', serif",
                                fontWeight: 700
                            }}
                        >
                            System Matrix
                        </Title>
                        <Text
                            style={{
                                fontSize: '16px',
                                color: THEME.subtext,
                                fontWeight: 500,
                                fontFamily: "'DM Sans', sans-serif",
                                display: 'block',
                                maxWidth: '750px',
                                lineHeight: '1.5'
                            }}
                        >
                            Global telemetry, service node health, and live execution tracing across the Vacanza infrastructure.
                        </Text>
                    </motion.div>
                </Col>

                <Col xs={24} lg={16}>
                    <Card
                        className="glass-card dashboard-section-card"
                        variant="borderless"
                        title={
                            <div>
                                <span style={{ fontSize: 20 }}>System Activity Breakdown</span>
                                <Text style={{ display: 'block', marginTop: 6, color: THEME.subtext, fontSize: 13, fontWeight: 500 }}>
                                    Shows how today&apos;s processed system operations are distributed across core service groups.
                                </Text>
                            </div>
                        }
                    >
                        <div style={{ padding: isMobile ? '0 4px' : '0 20px' }}>
                            {Object.values((data?.apiMetrics || []).reduce((acc, curr) => {
                                const category = getActivityCategory(curr.apiName);
                                if (!acc[category.name]) acc[category.name] = { ...category, value: 0 };
                                acc[category.name].value += (curr.totalCalls || 0);
                                return acc;
                            }, {})).sort((a, b) => b.value - a.value).map((item, index) => {
                                const COLORS = [THEME.coral, THEME.navy, '#2DD4A8', '#FFB347', '#00B4D8'];
                                const total = data?.apiMetrics?.reduce((acc, curr) => acc + (curr.totalCalls || 0), 0) || 1;
                                const percentage = Math.round((item.value / total) * 100);

                                return (
                                    <div key={index} style={{ marginBottom: 24 }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: isMobile ? 'flex-start' : 'center', marginBottom: 8, gap: 12, flexWrap: 'wrap' }}>
                                            <Space size="small" style={{ minWidth: 0 }}>
                                                <div style={{ width: 8, height: 8, borderRadius: '50%', background: COLORS[index % COLORS.length] }} />
                                                <Text strong style={{ color: THEME.navy, fontSize: 13 }}>{item.name}</Text>
                                            </Space>
                                            <Text style={{ fontSize: 13, fontWeight: 700, color: THEME.subtext, marginLeft: 'auto' }}>
                                                {item.value.toLocaleString()} <span style={{ color: 'rgba(0,0,0,0.2)', fontWeight: 400 }}>({percentage}% of total activity)</span>
                                            </Text>
                                        </div>
                                        <Text style={{ display: 'block', color: THEME.subtext, fontSize: 12, marginBottom: 10, lineHeight: 1.45 }}>
                                            {item.description}
                                        </Text>
                                        <div style={{ height: 12, background: 'rgba(26, 35, 50, 0.04)', borderRadius: '6px', overflow: 'hidden' }}>
                                            <motion.div
                                                initial={{ width: 0 }}
                                                animate={{ width: `${percentage}%` }}
                                                transition={{ duration: 1, delay: index * 0.1 }}
                                                style={{
                                                    height: '100%',
                                                    background: COLORS[index % COLORS.length],
                                                    borderRadius: '6px',
                                                    boxShadow: `0 0 10px ${COLORS[index % COLORS.length]}44`
                                                }}
                                            />
                                        </div>
                                    </div>
                                );
                            })}
                            <div style={{
                                marginTop: 40,
                                padding: '20px',
                                background: 'rgba(26, 35, 50, 0.02)',
                                borderRadius: '16px',
                                border: '1px solid rgba(26, 35, 50, 0.05)',
                                textAlign: 'center'
                            }}>
                                <Text style={{ display: 'block', fontSize: 11, color: THEME.subtext, textTransform: 'uppercase', letterSpacing: 2, fontWeight: 700, marginBottom: 4 }}>Total Operations Today</Text>
                                <Title level={2} style={{ margin: '4px 0', fontWeight: 900, color: THEME.navy }}>
                                    {(data?.apiMetrics?.reduce((acc, curr) => acc + (curr.totalCalls || 0), 0) || 0).toLocaleString()}
                                </Title>
                                <Text style={{ display: 'block', fontSize: 12, color: 'rgba(26, 35, 50, 0.4)', fontWeight: 600 }}>Total actions processed across Vacanza services today.</Text>
                            </div>
                        </div>
                    </Card>

                    <Card className="glass-card dashboard-section-card" variant="borderless" title={<span style={{ fontSize: 20 }}>Service Node Topography</span>} style={{ marginTop: isMobile ? 24 : 48 }}>
                        <Table
                            columns={serviceColumns}
                            dataSource={[...(data?.services || [])].sort((a, b) => {
                                const aIsInternal = !SERVICE_KEY_MAP[a.name];
                                const bIsInternal = !SERVICE_KEY_MAP[b.name];
                                if (aIsInternal && !bIsInternal) return 1;
                                if (!aIsInternal && bIsInternal) return -1;
                                return 0;
                            })}
                            pagination={false}
                            rowKey="name"
                            style={{ marginTop: 24 }}
                            scroll={{ x: 760 }}
                        />
                        <div style={{ marginTop: 16, padding: '12px 16px', background: 'rgba(26, 35, 50, 0.02)', borderRadius: '12px', border: '1px dashed rgba(26, 35, 50, 0.1)' }}>
                            <Text type="secondary" style={{ fontSize: 12 }}>
                                <span style={{ marginRight: 8 }}>💡</span>
                                <b>System Insight:</b> The millisecond (ms) values in parentheses represent the round-trip response time between Vacanza and the provider.
                                <span style={{ color: THEME.green, fontWeight: 700 }}> Under 500ms</span> is Excellent,
                                <span style={{ color: THEME.warning, fontWeight: 700 }}> under 2000ms</span> is Normal,
                                <span style={{ color: THEME.error, fontWeight: 700 }}> above</span> indicates a slow connection.
                            </Text>
                        </div>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card className="glass-card dashboard-section-card" variant="borderless" title={<span style={{ fontSize: 20 }}>System Vitality Monitor</span>}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: isMobile ? 20 : 32 }}>
                            <div style={{ padding: isMobile ? '20px' : '32px', background: 'rgba(26, 35, 50, 0.04)', borderRadius: '24px' }}>
                                <Text style={{ fontSize: 12, color: THEME.subtext, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 12 }}>Overall System Integrity</Text>
                                <Title level={1} style={{ margin: '0 0 12px 0', color: THEME.navy, fontWeight: 800, fontSize: isMobile ? 38 : 48 }}>{Math.round((data?.systemHealth || 0) * 100)}%</Title>
                                <Progress percent={Math.round((data?.systemHealth || 0) * 100)} strokeColor={THEME.green} status="active" size={12} />
                            </div>

                            <div style={{ padding: isMobile ? '20px' : '32px', background: `${THEME.navy}`, borderRadius: '24px', color: 'white' }}>
                                <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 16 }}>Network Continuity</Text>

                                <div style={{ marginBottom: 20 }}>
                                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, flexWrap: 'wrap' }}>
                                        <Title level={1} style={{ margin: 0, color: 'white', fontWeight: 900, fontSize: isMobile ? 34 : 42 }}>
                                            {Math.floor((data?.uptimeSeconds || 0) / 86400)}
                                        </Title>
                                        <Text style={{ color: THEME.green, fontWeight: 800, fontSize: 16 }}>DAYS ONLINE</Text>
                                    </div>
                                    <Text style={{ color: 'rgba(255,255,255,0.3)', fontSize: 13, fontWeight: 600 }}>
                                        {Math.floor(((data?.uptimeSeconds || 0) % 86400) / 3600)} Hours {Math.floor(((data?.uptimeSeconds || 0) % 3600) / 60)} Mins Without Interruption
                                    </Text>
                                </div>

                                <div style={{
                                    borderTop: '1px solid rgba(255,255,255,0.1)',
                                    paddingTop: 16,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'space-between',
                                    gap: 12,
                                    flexWrap: 'wrap'
                                }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                        <Badge status="processing" color={THEME.green} />
                                        <Text style={{ color: 'rgba(255,255,255,0.8)', fontSize: 13, fontWeight: 600 }}>Status: <span style={{ color: THEME.green }}>Excellent</span></Text>
                                    </div>
                                    <Tag color="rgba(45, 212, 168, 0.1)" style={{ margin: 0, color: THEME.green, border: 'none', fontSize: 10 }}>ACTIVE</Tag>
                                </div>
                            </div>
                        </div>

                        <div style={{
                            marginTop: isMobile ? 24 : 48,
                            background: '#06080b',
                            borderRadius: '32px',
                            padding: isMobile ? '16px' : '24px',
                            height: isMobile ? 'auto' : 520,
                            minHeight: isMobile ? 320 : undefined,
                            display: 'flex',
                            flexDirection: 'column',
                            boxShadow: '0 30px 60px rgba(0,0,0,0.4)',
                            border: '1px solid rgba(255,255,255,0.05)',
                            overflow: 'hidden'
                        }}>
                            <div style={{
                                display: 'flex',
                                justifyContent: 'space-between',
                                alignItems: 'center',
                                marginBottom: 20,
                                paddingBottom: 16,
                                borderBottom: '1px solid rgba(255,255,255,0.03)'
                            }}>
                                <div style={{ display: 'flex', gap: 8 }}>
                                    <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#ff5f56' }} />
                                    <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#ffbd2e' }} />
                                    <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#27c93f' }} />
                                </div>
                                <Tag variant="filled" style={{ margin: 0, background: 'rgba(45, 212, 168, 0.1)', color: THEME.green, fontWeight: 800, fontSize: 10, letterSpacing: 1 }}>LIVE_TRACE</Tag>
                            </div>

                            <div style={{
                                flex: 1,
                                minHeight: 0,
                                overflowY: 'auto',
                                paddingRight: 8,
                                scrollbarWidth: 'thin',
                                scrollbarColor: 'rgba(45, 212, 168, 0.2) transparent'
                            }}>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                                    {(data?.logs || []).map((log, idx) => (
                                        <div key={idx} style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', lineHeight: 1.6, display: 'flex', flexWrap: 'wrap' }}>
                                            <span style={{ color: THEME.green, opacity: 0.8, whiteSpace: 'nowrap' }}>[{dayjs(log.timestamp).format('HH:mm:ss')}]</span>
                                            <span style={{
                                                color: log.level === 'ERROR' ? THEME.coral : log.level === 'WARN' ? THEME.amber : '#5A6B7A',
                                                marginLeft: 12,
                                                fontWeight: 800,
                                                minWidth: isMobile ? 'auto' : 50
                                            }}>{log.level}</span>
                                            <span style={{ color: '#e2e8f0', marginLeft: 12, wordBreak: 'break-word' }}>{log.message}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div >
    );
};

export default Monitoring;
