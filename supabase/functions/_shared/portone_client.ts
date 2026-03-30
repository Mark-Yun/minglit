export interface PortonePlatformPartner {
  id: string;
  name: string;
  contact?: Record<string, unknown>;
  account?: Record<string, unknown>;
  type?: Record<string, unknown>;
  taxationType?: string;
  memo?: string;
  tags?: string[];
  [key: string]: unknown;
}

export interface PortoneOrderTransferOrderDetail {
  orderAmount: number;
  [key: string]: unknown;
}

export interface PortoneOrderTransfer {
  transfer?: {
    type: string;
    id: string;
    partnerId: string;
    paymentId?: string;
    orderDetail?: PortoneOrderTransferOrderDetail;
    settlementDate?: string;
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

export interface PortoneSettlement {
  id?: string;
  partnerId?: string;
  transferId?: string;
  amount?: number;
  currency?: string;
  settlementDate?: string;
  [key: string]: unknown;
}

export interface PortonePayout {
  id?: string;
  partnerId?: string;
  amount?: number;
  currency?: string;
  [key: string]: unknown;
}

export interface PortonePageFilter {
  number?: number;
  size?: number;
}

export interface PortonePayoutRequest {
  bulkPayoutId?: string;
  name?: string;
  partnerSettlementIds: string[];
  isForTest?: boolean;
  [key: string]: unknown;
}

export interface PortonePayoutResponse {
  bulkPayoutId?: string;
  bulkPayoutGraphqlId?: string;
  payoutCount?: number;
  [key: string]: unknown;
}

export interface PortoneTransfer {
  type?: string;
  id?: string;
  graphqlId?: string;
  partnerId?: string;
  status?: string;
  settlementDate?: string;
  settlementAmount?: number;
  currency?: string;
  [key: string]: unknown;
}

export class PortoneV2Client {
  private apiKey: string;
  private baseUrl = Deno.env.get('PORTONE_V2_API_URL') || "https://api.portone.io";

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async getIdentityVerification(verificationId: string): Promise<Record<string, unknown>> {
    const response = await fetch(`${this.baseUrl}/identity-verifications/${verificationId}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async createPartner(body: {
    id: string;
    name: string;
    contact?: Record<string, unknown>;
    account?: Record<string, unknown>;
    type?: Record<string, unknown>;
    taxationType?: string;
    memo?: string;
    tags?: string[];
  }): Promise<PortonePlatformPartner> {
    const response = await fetch(`${this.baseUrl}/platform/partners`, {
      method: "POST",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async getPartner(partnerId: string): Promise<PortonePlatformPartner> {
    const response = await fetch(`${this.baseUrl}/platform/partners/${partnerId}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async createOrderTransfer(body: {
    partnerId: string;
    paymentId: string;
    orderDetail: PortoneOrderTransferOrderDetail;
    settlementStartDate?: string;
    settlementDate?: string;
    [key: string]: unknown;
  }): Promise<PortoneOrderTransfer> {
    const response = await fetch(`${this.baseUrl}/platform/transfers/order`, {
      method: "POST",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async createOrderCancelTransfer(body: {
    partnerId?: string;
    paymentId?: string;
    cancellationId: string;
    [key: string]: unknown;
  }): Promise<Record<string, unknown>> {
    const response = await fetch(`${this.baseUrl}/platform/transfers/order-cancel`, {
      method: "POST",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async getPartnerSettlements(filter?: {
    partnerId?: string;
    dateRange?: { from?: string; until?: string };
    page?: PortonePageFilter;
  }): Promise<{ settlements: PortoneSettlement[]; page: Record<string, unknown> }> {
    const params = new URLSearchParams();
    if (filter?.partnerId) params.set("partnerId", filter.partnerId);
    if (filter?.dateRange?.from) params.set("dateRange.from", filter.dateRange.from);
    if (filter?.dateRange?.until) params.set("dateRange.until", filter.dateRange.until);
    if (filter?.page?.number !== undefined) params.set("page.number", String(filter.page.number));
    if (filter?.page?.size !== undefined) params.set("page.size", String(filter.page.size));
    const qs = params.toString();
    const response = await fetch(`${this.baseUrl}/platform/partner-settlements${qs ? `?${qs}` : ""}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async getPayouts(filter?: {
    partnerId?: string;
    page?: PortonePageFilter;
  }): Promise<{ payouts: PortonePayout[]; page: Record<string, unknown> }> {
    const params = new URLSearchParams();
    if (filter?.partnerId) params.set("partnerId", filter.partnerId);
    if (filter?.page?.number !== undefined) params.set("page.number", String(filter.page.number));
    if (filter?.page?.size !== undefined) params.set("page.size", String(filter.page.size));
    const qs = params.toString();
    const response = await fetch(`${this.baseUrl}/platform/payouts${qs ? `?${qs}` : ""}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async requestPayout(params: PortonePayoutRequest): Promise<PortonePayoutResponse> {
    const response = await fetch(`${this.baseUrl}/platform/partner-settlements/complete-payout`, {
      method: "POST",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(params),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async getPayoutDetail(payoutId: string): Promise<PortonePayout> {
    const response = await fetch(`${this.baseUrl}/platform/payouts/${payoutId}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }

  async getPartnerTransfers(filter?: {
    partnerId?: string;
    page?: PortonePageFilter;
  }): Promise<{ transferSummaries: PortoneTransfer[]; page: Record<string, unknown> }> {
    const body: Record<string, unknown> = {};
    if (filter?.page) {
      body.page = filter.page;
    }
    if (filter?.partnerId) {
      body.filter = { partnerIds: [filter.partnerId] };
    }
    const response = await fetch(`${this.baseUrl}/platform/transfer-summaries`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    return await response.json();
  }
}
