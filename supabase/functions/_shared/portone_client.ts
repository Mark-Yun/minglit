export class PortoneV2Client {
  private apiKey: string;
  private baseUrl = "https://api.portone.io";

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
}
