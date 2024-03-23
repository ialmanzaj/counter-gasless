import { CallWithERC2771Request, ERC2771Type, GelatoRelay } from "@gelatonetwork/relay-sdk";
import { ethers, TypedDataField } from "ethers";
import * as dotenv from "dotenv";

dotenv.config({ path: ".env" });

const ALCHEMY_ID = process.env.API_KEY_ALCHEMY;
const GELATO_RELAY_API_KEY = process.env.GELATO_RELAY_API_KEY;

const RPC_URL = `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_ID}`;

const provider = new ethers.JsonRpcProvider(RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string, provider);

const relay = new GelatoRelay();

export interface ISign {
  (
    domain: ethers.TypedDataDomain,
    types: Record<string, Array<TypedDataField>>,
    // eslint-disable-next-line
    value: Record<string, any>,
  ): Promise<string>;
}

const signPermit = async (
  value: bigint,
  token: string,
  sender: string,
  spender: string,
  deadline: number,
  chainId: number,
  signTypedData: ISign,
): Promise<ethers.Signature | null> => {
  const domain: ethers.TypedDataDomain = {
    name: "USD Coin",
    version: "2",
    chainId: chainId,
    verifyingContract: token,
  };

  const types = {
    Permit: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  };
  const nonce = ethers.randomBytes(32);

  const data = {
    owner: sender,
    spender: spender,
    value: value,
    nonce: nonce,
    deadline: deadline,
  };

  try {
    const signature = await signTypedData(domain, types, data);
    return ethers.Signature.from(signature);
  } catch (e) {
    return null;
  }
};

const testSponsoredCallERC2771WithSignature = async () => {
  const gasless_token = "0xc8e5E33E054E312d8A9BbA80012f87bCF989b961";
  const deployer = "0x3bC25D139069Ca06f7079fE67dcEd166b40edA9e";
  const usdc = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
  const abi = [
    "function send(IERC20Permit token, address sender, address receiver, uint256 amount,uint256 deadline,uint8 v,bytes32 r,bytes32 s)",
  ];

  const user = await signer.getAddress();

  // Generate the target payload
  const contract = new ethers.Contract(gasless_token, abi, signer);

  const chainId = (await provider!.getNetwork()).chainId;

  // sign permit signature
  const deadline = Math.floor(Date.now() / 1000) + 60;
  const maxFee = ethers.parseEther("30");

  const sig = await signPermit(
    ethers.parseUnits("10", 6),
    usdc,
    user,
    deployer,
    deadline,
    Number(chainId), // Sepolia
    signer.signTypedData,
  );

  if (!sig) throw new Error("Invalid signature");

  const { v, r, s } = sig;

  const { data } = await contract.send.populateTransaction(usdc, maxFee, deadline, v, r, s);

  // Populate a relay request
  const request: CallWithERC2771Request = {
    chainId,
    target: gasless_token,
    data: data as string,
    user: user as string,
  };

  // sign the Payload and get struct and signature
  const { struct, signature } = await relay.getSignatureDataERC2771(request, signer, ERC2771Type.SponsoredCall);

  // send the request with signature
  const response = await relay.sponsoredCallERC2771WithSignature(struct, signature, GELATO_RELAY_API_KEY!);

  console.log(`https://relay.gelato.digital/tasks/status/${response.taskId}`);
};

testSponsoredCallERC2771WithSignature();
