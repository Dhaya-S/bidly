import React, { useEffect, useState } from 'react';
import { Table, Button, Modal, Input, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { reportsApi } from '../../api/reports.api';
import type { OrderReport } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatDate } from '../../utils/format';

export const ReportListPage: React.FC = () => {
  const navigate = useNavigate();
  const [reports, setReports] = useState<OrderReport[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedReport, setSelectedReport] = useState<OrderReport | null>(null);
  const [adminNote, setAdminNote] = useState<string>('');

  const fetchReports = async () => {
    try {
      const res = await reportsApi.getReports();
      setReports(res.content);
    } catch {
      message.error('Failed to load reports');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const handleResolve = async (action: 'RESOLVED' | 'DISMISSED') => {
    if (!selectedReport) return;
    await reportsApi.updateReportStatus(selectedReport.id, action, adminNote);
    message.success(`Dispute marked as ${action.toLowerCase()}`);
    setSelectedReport(null);
    setAdminNote('');
    fetchReports();
  };

  const columns: ColumnsType<OrderReport> = [
    {
      title: 'Report ID',
      dataIndex: 'id',
      key: 'id',
      render: (val) => <span style={{ fontWeight: 600, color: '#0F172A' }}>{val}</span>,
    },
    {
      title: 'Order Number',
      dataIndex: 'orderNumber',
      key: 'orderNumber',
      render: (val) => (
        <span style={{ color: '#0D9488', fontWeight: 600, cursor: 'pointer' }}>
          {val}
        </span>
      ),
    },
    {
      title: 'Reporter',
      key: 'reporter',
      render: (_, record) => (
        <span
          onClick={() => navigate(`/users/${record.reporterId}`)}
          style={{ color: '#0D9488', cursor: 'pointer', fontWeight: 500 }}
        >
          {record.reporter?.name}
        </span>
      ),
    },
    {
      title: 'Reason & Details',
      key: 'reason',
      render: (_, record) => (
        <div style={{ maxWidth: 360 }}>
          <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '13px' }}>
            {record.reason}
          </div>
          <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
            {record.details}
          </div>
        </div>
      ),
    },
    {
      title: 'Priority',
      dataIndex: 'priority',
      key: 'priority',
      render: (val) => (
        <span
          style={{
            fontWeight: 700,
            fontSize: '12px',
            color: val === 'CRITICAL' ? '#EF4444' : val === 'HIGH' ? '#F59E0B' : '#64748B',
          }}
        >
          {val}
        </span>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (val) => <StatusBadge status={val} />,
    },
    {
      title: 'Created Date',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (val) => <span style={{ fontSize: '12px', color: '#64748B' }}>{formatDate(val)}</span>,
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: (_, record) => (
        <Button
          type="primary"
          size="small"
          onClick={() => setSelectedReport(record)}
          style={{ backgroundColor: '#0D9488', borderRadius: '6px', fontWeight: 500 }}
        >
          Manage
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Reports & Disputes
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Buyer-seller conflicts, order delivery complaints, and refund arbitrations
        </p>
      </div>

      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}
      >
        <Table
          columns={columns}
          dataSource={reports}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>

      {/* Action Modal */}
      <Modal
        title={`Resolve Dispute - ${selectedReport?.orderNumber}`}
        open={!!selectedReport}
        onCancel={() => setSelectedReport(null)}
        footer={[
          <Button key="dismiss" danger onClick={() => handleResolve('DISMISSED')}>
            Dismiss Dispute
          </Button>,
          <Button
            key="resolve"
            type="primary"
            style={{ backgroundColor: '#0D9488' }}
            onClick={() => handleResolve('RESOLVED')}
          >
            Resolve & Complete
          </Button>,
        ]}
      >
        {selectedReport && (
          <div style={{ padding: '12px 0' }}>
            <div style={{ marginBottom: '12px' }}>
              <strong>Reporter:</strong> {selectedReport.reporter?.name} ({selectedReport.reporter?.phone})
            </div>
            <div style={{ marginBottom: '12px' }}>
              <strong>Reason:</strong> {selectedReport.reason}
            </div>
            <div style={{ marginBottom: '16px', color: '#475569' }}>
              <strong>Details:</strong> {selectedReport.details}
            </div>
            <div>
              <label style={{ display: 'block', fontWeight: 600, fontSize: '13px', marginBottom: '6px' }}>
                Admin Resolution Note
              </label>
              <Input.TextArea
                rows={3}
                placeholder="Explain the resolution decision communicated to both buyer and seller..."
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
              />
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
