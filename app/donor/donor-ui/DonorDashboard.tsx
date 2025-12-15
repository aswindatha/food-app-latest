
import React, { useEffect, useMemo, useRef, useState } from 'react';
import axios from 'axios';
import styled, { css, keyframes } from 'styled-components';

type DonationStatus = 'current' | 'donated' | 'expired' | string;

type Donation = {
  id: number;
  title: string;
  description?: string | null;
  foodType: string;
  quantity: number;
  unit: string;
  expiryDate: string;
  pickupAddress: string;
  pickupTime?: string | null;
  status: DonationStatus;
  volunteerId?: number | null;
  organizationId?: number | null;
  createdAt: string;
};

type Conversation = {
  id: number;
  participant2Id: number;
  participant2Type: 'volunteer' | 'organization' | string;
  participant2Name: string;
  participant2Username: string;
  lastMessage?: string | null;
  lastMessageAt?: string | null;
  createdAt: string;
};

type Message = {
  id: number;
  senderId: number;
  senderName: string;
  senderUsername: string;
  messageText: string;
  isRead: boolean;
  createdAt: string;
};

type ApiResponse<T> = {
  success: boolean;
  message?: string;
  data: T;
};

type StoredUser = {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  roleId: number;
  roleName: string;
  isActive: boolean;
  emailVerified: boolean;
};

const fadeUp = keyframes`
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: translateY(0); }
`;

const shellBg = 'linear-gradient(135deg, #f6f8ff 0%, #eef2ff 100%)';

const Page = styled.div`
  min-height: 100vh;
  background: ${shellBg};
  color: #0f172a;
  display: flex;
  flex-direction: column;
`;

const TopBar = styled.div`
  position: sticky;
  top: 0;
  z-index: 20;
  padding: 16px 16px 12px;
  background: rgba(246, 248, 255, 0.75);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(148, 163, 184, 0.25);
`;

const TopBarInner = styled.div`
  max-width: 1080px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
`;

const Brand = styled.div`
  display: flex;
  align-items: center;
  gap: 10px;
`;

const BrandMark = styled.div`
  width: 36px;
  height: 36px;
  border-radius: 12px;
  background: linear-gradient(135deg, #4f46e5 0%, #06b6d4 100%);
  box-shadow: 0 10px 26px rgba(79, 70, 229, 0.25);
`;

const BrandText = styled.div`
  display: flex;
  flex-direction: column;
  line-height: 1.1;
`;

const BrandTitle = styled.div`
  font-weight: 800;
  letter-spacing: -0.02em;
`;

const BrandSubtitle = styled.div`
  font-size: 12px;
  color: #64748b;
`;

const HeaderRight = styled.div`
  display: flex;
  align-items: center;
  gap: 10px;
`;

const UserPill = styled.div`
  padding: 8px 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(148, 163, 184, 0.25);
  display: flex;
  align-items: center;
  gap: 10px;
`;

const Avatar = styled.div`
  width: 30px;
  height: 30px;
  border-radius: 12px;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  display: grid;
  place-items: center;
  font-weight: 800;
  font-size: 13px;
`;

const UserMeta = styled.div`
  display: flex;
  flex-direction: column;
  line-height: 1.05;
`;

const UserName = styled.div`
  font-weight: 700;
  font-size: 13px;
`;

const UserRole = styled.div`
  font-size: 11px;
  color: #64748b;
  text-transform: capitalize;
`;

const GhostButton = styled.button`
  border: 1px solid rgba(148, 163, 184, 0.35);
  background: rgba(255, 255, 255, 0.7);
  color: #0f172a;
  padding: 10px 12px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;

  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 10px 22px rgba(2, 6, 23, 0.08);
  }
`;

const Content = styled.div`
  flex: 1;
  width: 100%;
  max-width: 1080px;
  margin: 0 auto;
  padding: 18px 16px 88px;
  animation: ${fadeUp} 0.5s ease-out;
`;

const SectionTitleRow = styled.div`
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
`;

const SectionTitle = styled.h2`
  margin: 0;
  font-size: 18px;
  letter-spacing: -0.02em;
`;

const SectionHint = styled.div`
  color: #64748b;
  font-size: 12px;
`;

const Card = styled.div`
  background: rgba(255, 255, 255, 0.85);
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 18px;
  box-shadow: 0 20px 50px rgba(2, 6, 23, 0.08);
  overflow: hidden;
`;

const TabsRow = styled.div`
  display: flex;
  gap: 8px;
  padding: 12px;
  flex-wrap: wrap;
`;

const TabButton = styled.button<{ $active: boolean }>`
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(241, 245, 249, 0.6);
  color: #0f172a;
  padding: 10px 12px;
  border-radius: 14px;
  font-weight: 800;
  font-size: 12px;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease, background 0.15s ease;

  ${(props: { $active: boolean }) =>
    props.$active &&
    css`
      background: linear-gradient(135deg, rgba(79, 70, 229, 0.95) 0%, rgba(6, 182, 212, 0.95) 100%);
      border-color: rgba(79, 70, 229, 0.45);
      color: white;
      box-shadow: 0 16px 36px rgba(79, 70, 229, 0.22);
    `}

  &:hover {
    transform: translateY(-1px);
  }
`;

const Pill = styled.span<{ $tone: 'green' | 'amber' | 'slate' | 'indigo' }>`
  padding: 6px 10px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 800;
  border: 1px solid rgba(148, 163, 184, 0.25);

  ${(props: { $tone: 'green' | 'amber' | 'slate' | 'indigo' }) => {
    if (props.$tone === 'green') {
      return css`
        background: rgba(34, 197, 94, 0.12);
        color: #166534;
        border-color: rgba(34, 197, 94, 0.25);
      `;
    }
    if (props.$tone === 'amber') {
      return css`
        background: rgba(245, 158, 11, 0.12);
        color: #92400e;
        border-color: rgba(245, 158, 11, 0.25);
      `;
    }
    if (props.$tone === 'indigo') {
      return css`
        background: rgba(79, 70, 229, 0.12);
        color: #3730a3;
        border-color: rgba(79, 70, 229, 0.25);
      `;
    }
    return css`
      background: rgba(100, 116, 139, 0.12);
      color: #334155;
      border-color: rgba(100, 116, 139, 0.25);
    `;
  }}
`;

const DonationList = styled.div`
  padding: 6px 12px 14px;
  display: grid;
  gap: 10px;
`;

const DonationItem = styled.div`
  border-radius: 16px;
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(255, 255, 255, 0.9);
  padding: 12px;
  display: flex;
  gap: 12px;
  align-items: flex-start;
`;

const DonationIcon = styled.div`
  width: 42px;
  height: 42px;
  border-radius: 14px;
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.18) 0%, rgba(6, 182, 212, 0.16) 100%);
  display: grid;
  place-items: center;
  border: 1px solid rgba(34, 197, 94, 0.22);
  flex: 0 0 auto;
`;

const DonationMain = styled.div`
  flex: 1;
  min-width: 0;
`;

const DonationTop = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
`;

const DonationTitle = styled.div`
  font-weight: 900;
  letter-spacing: -0.01em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
`;

const DonationMeta = styled.div`
  margin-top: 6px;
  color: #475569;
  font-size: 12px;
  display: grid;
  gap: 4px;
`;

const InlineRow = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
`;

const EmptyState = styled.div`
  padding: 26px 16px 28px;
  text-align: center;
  color: #64748b;
  font-weight: 700;
`;

const ErrorBanner = styled.div`
  margin-bottom: 12px;
  padding: 12px 14px;
  border-radius: 16px;
  background: rgba(239, 68, 68, 0.12);
  border: 1px solid rgba(239, 68, 68, 0.25);
  color: #991b1b;
  font-weight: 800;
`;

const ChatShell = styled.div`
  display: grid;
  grid-template-columns: 340px 1fr;
  min-height: 540px;

  @media (max-width: 860px) {
    grid-template-columns: 1fr;
  }
`;

const ChatSidebar = styled.div`
  border-right: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(241, 245, 249, 0.45);
  @media (max-width: 860px) {
    border-right: none;
    border-bottom: 1px solid rgba(148, 163, 184, 0.25);
  }
`;

const ChatSidebarHeader = styled.div`
  padding: 14px 14px 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
`;

const Search = styled.input`
  width: 100%;
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(255, 255, 255, 0.85);
  border-radius: 14px;
  padding: 10px 12px;
  font-weight: 700;
  outline: none;

  &:focus {
    box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.14);
    border-color: rgba(79, 70, 229, 0.45);
  }
`;

const ConversationList = styled.div`
  padding: 8px;
  display: grid;
  gap: 8px;
  max-height: 520px;
  overflow: auto;
`;

const ConversationItem = styled.button<{ $active: boolean }>`
  width: 100%;
  text-align: left;
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(255, 255, 255, 0.85);
  border-radius: 16px;
  padding: 12px;
  cursor: pointer;
  display: grid;
  gap: 8px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;

  ${(props: { $active: boolean }) =>
    props.$active &&
    css`
      border-color: rgba(79, 70, 229, 0.35);
      box-shadow: 0 18px 40px rgba(79, 70, 229, 0.12);
    `}

  &:hover {
    transform: translateY(-1px);
  }
`;

const ConvTop = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
`;

const ConvName = styled.div`
  font-weight: 900;
  letter-spacing: -0.01em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
`;

const ConvSnippet = styled.div`
  color: #475569;
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
`;

const ChatMain = styled.div`
  display: flex;
  flex-direction: column;
  min-width: 0;
`;

const ChatMainHeader = styled.div`
  padding: 14px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.25);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
`;

const ChatTitle = styled.div`
  display: flex;
  flex-direction: column;
  gap: 2px;
`;

const ChatTitleName = styled.div`
  font-weight: 900;
  letter-spacing: -0.02em;
`;

const ChatTitleSub = styled.div`
  font-size: 12px;
  color: #64748b;
  text-transform: capitalize;
`;

const MessagesArea = styled.div`
  flex: 1;
  padding: 14px;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  background: radial-gradient(circle at 20% 0%, rgba(79, 70, 229, 0.08), transparent 35%),
    radial-gradient(circle at 90% 10%, rgba(6, 182, 212, 0.08), transparent 40%);
`;

const BubbleRow = styled.div<{ $mine: boolean }>`
  display: flex;
  justify-content: ${(props: { $mine: boolean }) => (props.$mine ? 'flex-end' : 'flex-start')};
`;

const Bubble = styled.div<{ $mine: boolean }>`
  max-width: 78%;
  border-radius: 18px;
  padding: 10px 12px;
  border: 1px solid rgba(148, 163, 184, 0.25);
  box-shadow: 0 14px 34px rgba(2, 6, 23, 0.08);
  background: rgba(255, 255, 255, 0.88);
  display: grid;
  gap: 6px;

  ${(props: { $mine: boolean }) =>
    props.$mine &&
    css`
      background: linear-gradient(135deg, rgba(79, 70, 229, 0.95) 0%, rgba(6, 182, 212, 0.95) 100%);
      color: white;
      border-color: rgba(79, 70, 229, 0.35);
    `}
`;

const BubbleMeta = styled.div<{ $mine: boolean }>`
  font-size: 11px;
  font-weight: 800;
  color: ${(props: { $mine: boolean }) => (props.$mine ? 'rgba(255,255,255,0.85)' : '#64748b')};
`;

const Composer = styled.form`
  padding: 12px;
  display: flex;
  gap: 10px;
  border-top: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(255, 255, 255, 0.75);
`;

const ComposerInput = styled.input`
  flex: 1;
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 16px;
  padding: 12px 12px;
  font-weight: 800;
  outline: none;

  &:focus {
    box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.14);
    border-color: rgba(79, 70, 229, 0.45);
  }
`;

const SendButton = styled.button`
  border: none;
  border-radius: 16px;
  padding: 12px 14px;
  font-weight: 900;
  cursor: pointer;
  background: linear-gradient(135deg, #4f46e5 0%, #06b6d4 100%);
  color: white;
  box-shadow: 0 18px 40px rgba(79, 70, 229, 0.22);
  transition: transform 0.15s ease;

  &:hover {
    transform: translateY(-1px);
  }

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
  }
`;

const Footer = styled.div`
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 12px 16px 18px;
  background: rgba(246, 248, 255, 0.85);
  backdrop-filter: blur(12px);
  border-top: 1px solid rgba(148, 163, 184, 0.25);
`;

const FooterInner = styled.div`
  max-width: 520px;
  margin: 0 auto;
  background: rgba(255, 255, 255, 0.85);
  border: 1px solid rgba(148, 163, 184, 0.25);
  box-shadow: 0 20px 50px rgba(2, 6, 23, 0.1);
  border-radius: 22px;
  padding: 8px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
`;

const NavButton = styled.button<{ $active: boolean }>`
  border: none;
  border-radius: 18px;
  padding: 10px 10px;
  cursor: pointer;
  font-weight: 900;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  color: #0f172a;
  background: transparent;

  ${(props: { $active: boolean }) =>
    props.$active &&
    css`
      background: linear-gradient(135deg, rgba(79, 70, 229, 0.95) 0%, rgba(6, 182, 212, 0.95) 100%);
      color: white;
      box-shadow: 0 18px 40px rgba(79, 70, 229, 0.22);
    `}
`;

function formatDateTime(value?: string | null) {
  if (!value) return '';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleString();
}

function formatShort(value?: string | null) {
  if (!value) return '';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function toneForDonationStatus(status: DonationStatus): 'green' | 'amber' | 'slate' | 'indigo' {
  const s = (status || '').toString().toLowerCase();
  if (s === 'current') return 'green';
  if (s === 'donated') return 'indigo';
  if (s === 'expired') return 'amber';
  return 'slate';
}

function donationLabel(status: DonationStatus) {
  const s = (status || '').toString().toLowerCase();
  if (s === 'current') return 'Current';
  if (s === 'donated') return 'Donated';
  if (s === 'expired') return 'Expired';
  return status;
}

const Icon = ({ name }: { name: 'home' | 'chat' | 'leaf' | 'send' }) => {
  if (name === 'home') {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M4 10.5L12 4l8 6.5v8.5a2 2 0 0 1-2 2h-4v-6H10v6H6a2 2 0 0 1-2-2v-8.5Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
      </svg>
    );
  }
  if (name === 'chat') {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M21 12a8 8 0 0 1-8 8H7l-4 3V12a8 8 0 1 1 18 0Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
        <path d="M8 12h8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      </svg>
    );
  }
  if (name === 'send') {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M22 2 11 13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        <path d="M22 2 15 22l-4-9-9-4 20-7Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
      </svg>
    );
  }
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 3c4 0 8 3 8 7 0 6-8 11-8 11S4 16 4 10c0-4 4-7 8-7Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
      <path d="M12 6c-2.2 0-4 1.4-4 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
};

const DonorDashboardPage: React.FC = () => {
  const API_BASE_URL = 'http://localhost:8080/api/donor';
  const [activeTab, setActiveTab] = useState<'home' | 'chat'>('home');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [donations, setDonations] = useState<Donation[]>([]);
  const [donationFilter, setDonationFilter] = useState<'all' | 'current' | 'donated' | 'expired'>('all');

  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [conversationSearch, setConversationSearch] = useState('');
  const [activeConversationId, setActiveConversationId] = useState<number | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [composerText, setComposerText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement | null>(null);

  const storedUser: StoredUser | null = useMemo(() => {
    try {
      const raw = localStorage.getItem('user');
      if (!raw) return null;
      return JSON.parse(raw) as StoredUser;
    } catch {
      return null;
    }
  }, []);

  const donorId = storedUser?.id;

  const filteredDonations = useMemo(() => {
    const list = donations.slice();
    if (donationFilter === 'all') return list;
    return list.filter((d: Donation) => (d.status || '').toString().toLowerCase() === donationFilter);
  }, [donations, donationFilter]);

  const donationCounts = useMemo(() => {
    const counts = { current: 0, donated: 0, expired: 0 };
    donations.forEach((d: Donation) => {
      const s = (d.status || '').toString().toLowerCase();
      if (s === 'current') counts.current += 1;
      if (s === 'donated') counts.donated += 1;
      if (s === 'expired') counts.expired += 1;
    });
    return counts;
  }, [donations]);

  const visibleConversations = useMemo(() => {
    const q = conversationSearch.trim().toLowerCase();
    const list = conversations.slice();
    if (!q) return list;
    return list.filter((c: Conversation) => {
      return (
        c.participant2Name.toLowerCase().includes(q) ||
        c.participant2Username.toLowerCase().includes(q) ||
        (c.participant2Type || '').toLowerCase().includes(q) ||
        (c.lastMessage || '').toLowerCase().includes(q)
      );
    });
  }, [conversations, conversationSearch]);

  const activeConversation = useMemo(() => {
    if (!activeConversationId) return null;
    return conversations.find((c: Conversation) => c.id === activeConversationId) || null;
  }, [activeConversationId, conversations]);

  const authHeaders = useMemo(() => {
    const token = localStorage.getItem('authToken');
    if (!token) return {};
    return { Authorization: `Bearer ${token}` };
  }, []);

  const fetchDonations = async () => {
    if (!donorId) {
      setError('Not logged in. Please login again.');
      return;
    }
    const res = await axios.get<ApiResponse<{ donations: Donation[] }>>(`${API_BASE_URL}/donations/${donorId}`, {
      headers: authHeaders,
    });
    const list = res.data?.data?.donations ?? [];
    setDonations(list);
  };

  const fetchConversations = async () => {
    if (!donorId) {
      setError('Not logged in. Please login again.');
      return;
    }
    const res = await axios.get<ApiResponse<{ conversations: Conversation[] }>>(`${API_BASE_URL}/conversations/${donorId}`, {
      headers: authHeaders,
    });
    const list = res.data?.data?.conversations ?? [];
    setConversations(list);
    if (!activeConversationId && list.length > 0) {
      setActiveConversationId(list[0].id);
    }
  };

  const fetchMessages = async (conversationId: number) => {
    const res = await axios.get<ApiResponse<{ messages: Message[] }>>(`${API_BASE_URL}/messages/${conversationId}`, {
      headers: authHeaders,
    });
    setMessages(res.data?.data?.messages ?? []);
  };

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      setLoading(true);
      setError('');
      try {
        await Promise.all([fetchDonations(), fetchConversations()]);
      } catch (e: any) {
        if (!mounted) return;
        setError(e?.response?.data?.message || e?.message || 'Failed to load donor dashboard.');
      } finally {
        if (mounted) setLoading(false);
      }
    };
    load();
    return () => {
      mounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!activeConversationId) return;
    let mounted = true;
    const load = async () => {
      try {
        await fetchMessages(activeConversationId);
      } catch (e: any) {
        if (!mounted) return;
        setError(e?.response?.data?.message || e?.message || 'Failed to load messages.');
      }
    };
    load();
    return () => {
      mounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeConversationId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, activeTab, activeConversationId]);

  const onLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    window.location.href = '/';
  };

  const sendMessage = async () => {
    if (!activeConversationId || !donorId) return;
    const text = composerText.trim();
    if (!text) return;

    setComposerText('');
    try {
      await axios.post<ApiResponse<any>>(
        `${API_BASE_URL}/messages/send`,
        {
          conversationId: activeConversationId,
          senderId: donorId,
          messageText: text,
        },
        { headers: authHeaders }
      );
      await Promise.all([fetchMessages(activeConversationId), fetchConversations()]);
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to send message.');
    }
  };

  const initials = useMemo(() => {
    const f = storedUser?.firstName?.[0] || 'D';
    const l = storedUser?.lastName?.[0] || '';
    return `${f}${l}`.toUpperCase();
  }, [storedUser?.firstName, storedUser?.lastName]);

  return (
    <Page>
      <TopBar>
        <TopBarInner>
          <Brand>
            <BrandMark />
            <BrandText>
              <BrandTitle>Donor Dashboard</BrandTitle>
              <BrandSubtitle>Track donations, chat fast, make impact</BrandSubtitle>
            </BrandText>
          </Brand>
          <HeaderRight>
            {storedUser && (
              <UserPill>
                <Avatar>{initials}</Avatar>
                <UserMeta>
                  <UserName>{storedUser.firstName} {storedUser.lastName}</UserName>
                  <UserRole>{storedUser.roleName}</UserRole>
                </UserMeta>
              </UserPill>
            )}
            <GhostButton type="button" onClick={onLogout}>Logout</GhostButton>
          </HeaderRight>
        </TopBarInner>
      </TopBar>

      <Content>
        {error && <ErrorBanner>{error}</ErrorBanner>}

        {activeTab === 'home' && (
          <>
            <SectionTitleRow>
              <SectionTitle>My Donations</SectionTitle>
              <SectionHint>{loading ? 'Loading…' : 'Current on top · Donated next · Expired last'}</SectionHint>
            </SectionTitleRow>
            <Card>
              <TabsRow>
                <TabButton type="button" $active={donationFilter === 'all'} onClick={() => setDonationFilter('all')}>
                  All
                </TabButton>
                <TabButton type="button" $active={donationFilter === 'current'} onClick={() => setDonationFilter('current')}>
                  Current <Pill $tone="green">{donationCounts.current}</Pill>
                </TabButton>
                <TabButton type="button" $active={donationFilter === 'donated'} onClick={() => setDonationFilter('donated')}>
                  Donated <Pill $tone="indigo">{donationCounts.donated}</Pill>
                </TabButton>
                <TabButton type="button" $active={donationFilter === 'expired'} onClick={() => setDonationFilter('expired')}>
                  Expired <Pill $tone="amber">{donationCounts.expired}</Pill>
                </TabButton>
                <TabButton type="button" $active={false} onClick={() => { fetchDonations().catch(() => {}); }}>
                  Refresh
                </TabButton>
              </TabsRow>

              {filteredDonations.length === 0 ? (
                <EmptyState>No donations found for this section.</EmptyState>
              ) : (
                <DonationList>
                  {filteredDonations.map((d: Donation) => (
                    <DonationItem key={d.id}>
                      <DonationIcon>
                        <Icon name="leaf" />
                      </DonationIcon>
                      <DonationMain>
                        <DonationTop>
                          <DonationTitle>{d.title}</DonationTitle>
                          <Pill $tone={toneForDonationStatus(d.status)}>{donationLabel(d.status)}</Pill>
                        </DonationTop>
                        <DonationMeta>
                          <div><strong>{d.quantity}</strong> {d.unit} · <strong>{d.foodType}</strong></div>
                          <InlineRow>
                            <span>Expiry: <strong>{formatShort(d.expiryDate)}</strong></span>
                            {d.pickupTime ? <span>Pickup: <strong>{formatShort(d.pickupTime)}</strong></span> : null}
                          </InlineRow>
                          <div>Address: {d.pickupAddress}</div>
                          {d.description ? <div>{d.description}</div> : null}
                        </DonationMeta>
                      </DonationMain>
                    </DonationItem>
                  ))}
                </DonationList>
              )}
            </Card>
          </>
        )}

        {activeTab === 'chat' && (
          <>
            <SectionTitleRow>
              <SectionTitle>Chat</SectionTitle>
              <SectionHint>All conversations with volunteers & organizations</SectionHint>
            </SectionTitleRow>
            <Card>
              <ChatShell>
                <ChatSidebar>
                  <ChatSidebarHeader>
                    <Search
                      value={conversationSearch}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) => setConversationSearch(e.target.value)}
                      placeholder="Search chats…"
                    />
                  </ChatSidebarHeader>
                  <ConversationList>
                    {visibleConversations.length === 0 ? (
                      <EmptyState>No conversations yet.</EmptyState>
                    ) : (
                      visibleConversations.map((c: Conversation) => (
                        <ConversationItem
                          key={c.id}
                          type="button"
                          $active={c.id === activeConversationId}
                          onClick={() => setActiveConversationId(c.id)}
                        >
                          <ConvTop>
                            <ConvName>{c.participant2Name}</ConvName>
                            <Pill $tone="slate">{c.participant2Type}</Pill>
                          </ConvTop>
                          <ConvSnippet>{c.lastMessage || 'No messages yet'}</ConvSnippet>
                          <SectionHint>{formatDateTime(c.lastMessageAt || c.createdAt)}</SectionHint>
                        </ConversationItem>
                      ))
                    )}
                  </ConversationList>
                </ChatSidebar>

                <ChatMain>
                  <ChatMainHeader>
                    <ChatTitle>
                      <ChatTitleName>{activeConversation ? activeConversation.participant2Name : 'Select a conversation'}</ChatTitleName>
                      <ChatTitleSub>{activeConversation ? activeConversation.participant2Type : '—'}</ChatTitleSub>
                    </ChatTitle>
                    <GhostButton type="button" onClick={() => { fetchConversations().catch(() => {}); }}>
                      Refresh
                    </GhostButton>
                  </ChatMainHeader>

                  <MessagesArea>
                    {activeConversationId ? (
                      messages.length === 0 ? (
                        <EmptyState>No messages yet. Say hi!</EmptyState>
                      ) : (
                        messages.map((m: Message) => {
                          const mine = donorId ? m.senderId === donorId : false;
                          return (
                            <BubbleRow key={m.id} $mine={mine}>
                              <Bubble $mine={mine}>
                                <div>{m.messageText}</div>
                                <BubbleMeta $mine={mine}>{mine ? 'You' : m.senderName} · {formatDateTime(m.createdAt)}</BubbleMeta>
                              </Bubble>
                            </BubbleRow>
                          );
                        })
                      )
                    ) : (
                      <EmptyState>Select a conversation to start.</EmptyState>
                    )}
                    <div ref={messagesEndRef} />
                  </MessagesArea>

                  <Composer
                    onSubmit={(e) => {
                      e.preventDefault();
                      sendMessage().catch(() => {});
                    }}
                  >
                    <ComposerInput
                      value={composerText}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) => setComposerText(e.target.value)}
                      placeholder={activeConversationId ? 'Type a message…' : 'Select a conversation first…'}
                      disabled={!activeConversationId}
                    />
                    <SendButton type="submit" disabled={!activeConversationId || composerText.trim().length === 0}>
                      <Icon name="send" />
                      Send
                    </SendButton>
                  </Composer>
                </ChatMain>
              </ChatShell>
            </Card>
          </>
        )}
      </Content>

      <Footer>
        <FooterInner>
          <NavButton type="button" $active={activeTab === 'home'} onClick={() => setActiveTab('home')}>
            <Icon name="home" />
            Home
          </NavButton>
          <NavButton type="button" $active={activeTab === 'chat'} onClick={() => setActiveTab('chat')}>
            <Icon name="chat" />
            Chat
          </NavButton>
        </FooterInner>
      </Footer>
    </Page>
  );
};

export default DonorDashboardPage;

