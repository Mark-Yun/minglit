export class IamportClient {
  private apiKey: string;
  private apiSecret: string;
  private baseUrl = "https://api.iamport.kr";

  constructor(apiKey: string, apiSecret: string) {
    this.apiKey = apiKey;
    this.apiSecret = apiSecret;
  }

  async getToken(): Promise<string> {
    const res = await fetch(`${this.baseUrl}/users/getToken`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ imp_key: this.apiKey, imp_secret: this.apiSecret }),
    });
    if (!res.ok) throw new Error(`Failed to get token: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response.access_token;
  }

  async getCertification(impUid: string): Promise<any> {
    const token = await this.getToken();
    const res = await fetch(`${this.baseUrl}/certifications/${impUid}`, {
      headers: { "Authorization": `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`Failed to get certification: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response;
  }

  async getPayment(impUid: string): Promise<any> {
    const token = await this.getToken();
    const res = await fetch(`${this.baseUrl}/payments/${impUid}`, {
      headers: { "Authorization": `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`Failed to get payment: ${await res.text()}`);
    const data = await res.json();
    if (data.code !== 0) throw new Error(`Iamport Error: ${data.message}`);
    return data.response;
  }
}
