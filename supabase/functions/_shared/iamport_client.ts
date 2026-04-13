/** Typed subset of the Iamport V1 payment response used by callers. */
export interface IamportPayment {
  imp_uid: string;
  merchant_uid: string;
  status: string;
  amount: number;
  /** Unix epoch seconds; null when payment has not completed (e.g. ready/failed). */
  paid_at: number | null;
  [key: string]: unknown;
}

export class IamportClient {
  private apiKey: string;
  private apiSecret: string;
  private baseUrl = Deno.env.get("PORTONE_V1_API_URL") || "https://api.iamport.kr";

  constructor(apiKey: string, apiSecret: string) {
    this.apiKey = apiKey;
    this.apiSecret = apiSecret;
  }

  // Fix #1422: e2e_pay_ prefix → route to dev-mock-portone for simulator payments
  // This lets the tick simulator exercise the real payment flow without hitting prod PG.
  private isE2EPayment(paymentId: string): boolean {
    return paymentId.startsWith("e2e_pay_");
  }

  private getMockBaseUrl(): string {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    return `${supabaseUrl}/functions/v1/dev-mock-portone`;
  }

  private async getTokenFromBase(baseUrl: string): Promise<string> {
    const res = await fetch(`${baseUrl}/users/getToken`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ imp_key: this.apiKey, imp_secret: this.apiSecret }),
    });
    if (!res.ok) throw new Error(`Failed to get token: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response.access_token;
  }

  async getToken(): Promise<string> {
    return this.getTokenFromBase(this.baseUrl);
  }

  async getCertification(impUid: string): Promise<Record<string, unknown>> {
    const token = await this.getToken();
    const res = await fetch(`${this.baseUrl}/certifications/${impUid}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`Failed to get certification: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response;
  }

  async getPayment(impUid: string): Promise<IamportPayment> {
    // Fix #1422: e2e_pay_ prefix → dev-mock-portone (simulator), otherwise real PG
    const baseUrl = this.isE2EPayment(impUid) ? this.getMockBaseUrl() : this.baseUrl;
    const token = await this.getTokenFromBase(baseUrl);
    const res = await fetch(`${baseUrl}/payments/${impUid}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`Failed to get payment: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response;
  }

  async cancelPayment(
    impUid: string,
    reason: string,
    amount?: number,
    checksum?: number,
  ): Promise<Record<string, unknown>> {
    // Fix #1422: e2e_pay_ prefix → dev-mock-portone (simulator), otherwise real PG
    const baseUrl = this.isE2EPayment(impUid) ? this.getMockBaseUrl() : this.baseUrl;
    const token = await this.getTokenFromBase(baseUrl);
    const body: Record<string, unknown> = { imp_uid: impUid, reason };
    if (amount !== undefined) body.amount = amount;
    if (checksum !== undefined) body.checksum = checksum;
    const res = await fetch(`${baseUrl}/payments/cancel`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`Failed to cancel payment: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response;
  }
}
