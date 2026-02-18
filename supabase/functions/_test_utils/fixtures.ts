export const mockOrder = {
  payment_amount: 15000,
  status: "pending",
};

export const mockPaidPayment = {
  status: "paid",
  amount: 15000,
  merchant_uid: "order-123",
};

export const mockReadyPayment = {
  status: "ready",
  amount: 15000,
  merchant_uid: "order-123",
};

export const mockCertification = {
  certified: true,
  name: "Test User",
  birthday: "1990-01-01",
  gender: "female",
  phone: "01012341234",
  unique_key: "ci-123",
  unique_in_site: "di-456",
};

export const mockPortoneVerification = {
  status: "VERIFIED",
  verifiedCustomer: {
    name: "Test User",
    birthDate: "1990-01-01",
    gender: "FEMALE",
    phoneNumber: "01012341234",
    ci: "ci-123",
    di: "di-456",
  },
};

export const mockUser = {
  id: "user-123",
};

export const mockNotificationMessage = {
  msg_id: 1,
  read_ct: 0,
  message: {
    id: "trace-1",
    user_id: "user-123",
    type: "party_reminder",
    title: "Party Reminder",
    body: "Your party starts soon",
    category: "service",
    data: { deep_link: "app://party/1" },
    meta: { occurred_at: 1700000000 },
  },
};

export const mockVectorPartyMessage = {
  msg_id: 10,
  read_ct: 0,
  message: {
    id: "trace-party-1",
    type: "party_created",
    payload: {
      id: "party-1",
      title: "Awesome Party",
      description: { ops: [{ insert: "Fun time!" }] },
      tags: ["social"],
      location: { name: "Seoul" },
    },
    meta: { occurred_at: 1700000000 },
  },
};

export const mockVectorInteractionMessage = {
  msg_id: 11,
  read_ct: 0,
  message: {
    id: "trace-interaction-1",
    type: "user_interaction",
    payload: {
      user_id: "user-1",
      party_id: "party-1",
      action_type: "like",
    },
    meta: { occurred_at: 1700000000 },
  },
};

export const mockQueueUpdateMessage = {
  msg_id: 100,
  message: {
    user_id: "user-1",
    party_id: "party-1",
    action_type: "like",
  },
};

const firebasePrivateKey = `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDkfDu74qcxaFyt
NosaSj3Lgalf85mYdLBTT1WlJZMnOmCKJqHqr98cSeImTwjwn8vQM/F4US65qoPf
ZLOoeZ3bHpBqjIj/NEtpMvkdjH9OZvmxkQchQo+Br5F2JOTFabAemBbx9IjLnYaB
wWPWkETnj26MAIZbeY5P6YBmrqQ+SRa4GZD2VHK4N8YfH5AXSJA09gweH48Sm1nn
6sYjwW/VFC8YoqP66Zw3eTcZMrOLAvi0GCoorsFekX/eIhAardmg8Puj3LFNQvX/
UL/eQjq9MNuoA7b88paDZ9n9I6e9eu88TsLGi3jtHKg2+9AzOHtJmmzSFrU4cZbf
vu5dJoZhAgMBAAECggEAAy5ppIGQ42K5G55NTIXpG1rIUXIyWsmRJO/PWPfPdzXc
X0APdBWTzTCIKhFipfsLmvAGNi8nL+WcZXFhAQEEficMSrd/NtJzFFll14/7u8s6
Qcsrpr5nAh7ALz1vRAJnNd3XP/IwL2mXlFntenDSzMiV+PQO6toj7Z/qLkPTPJzA
LJe6cJS/zLO3bZ6TP0HbP5579zOhCi5GMSkm3Hb7AzitV4tIkHWWAOQ01TrIOMTf
U/ttVMjR5cDiANVhD6ETgAvJU6k4duKjSDIOuZ9mOue9SbOiTZsbmdglnDNCRzCN
F9QakHaDutJgne1hGH9ZRUcoApzwBpjzXXZft1FmIwKBgQDx4fInQ/mb26rDrqFo
TBXvnOCIwTKBTLwfxQdF23FCPZ1a7oNdxyfyavBGjq+x0LxG2+795u1kG0EDkJei
fxd3XnAHWg0XYzahBskIkNeC+iApTF83FCDAUL+BntGLDLKuBBCEo8PdXTiQR82E
nc2bd48npISeSD8xyTV15iwArwKBgQDx0h0GA/D3R0t3DZlECSt4w10Hcuwk+LQO
8z1FMcYDu73uDZyCK9vnqoedPHy1Q5P1W2K80eoiC/fCqORfk/lhhiz3P7KrazY6
FcCMm8uMVPVt67nR5wVmRc47X+aHLEVwqoLd46JhiNjjhtFtbJ0EZX4S4mYBL5t4
eGGVKscN7wKBgBY7to51aRQydNfXzW5Q0BNeUCVB3OqVqxUgfzKkoRx9nWEmW1zb
WYim278gjnXBwgyhWq5r85YoCynQuJ9vHzERtSp31Iw5ymOyw/fNmIGpjBs/seDW
MMx8n53Cg3BMkn/8T6hhhTdrwi9A6lsuRh/sNXRnYulJqsVgwVE8/v5xAoGBAJtz
6Ph+/B7alCa6dTaJdoqxfFJXjHrP7mBV+aNLtfGcdSJdWalMrJcmxvtLcRfNk4X8
82JSx2KPsvxOOlE+/Oe2q51eM2uDBl8csKUzWgyiaQv6p3/KNWxjn4oHwlhPG2ys
EGi39yEgKd1KQ8NGOUIkRIG7TLuicR1mtcSAtWm9AoGAXpfcHYt4lpvlRcSHashK
1ZrR2zZ7DvKnZtvEN9UuXcvhXtRAu79EkHXF5vGty+UV8af8Rk1q9t986YugAyxX
H5xIN+WHLTzAqU/24JV3gTAQPmpEi5BfPXRTlNMRPVNLP6srEDcsc7kagROUqQYF
oyQEyXRDP+Sitzo9XI6zwGA=
-----END PRIVATE KEY-----`;

export const firebaseServiceAccount = {
  private_key: firebasePrivateKey,
  client_email: "test-firebase@minglit.example",
  project_id: "minglit-test",
};

export const firebaseServiceAccountJson = JSON.stringify(firebaseServiceAccount);
