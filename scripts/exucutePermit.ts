import { Contract, ethers } from 'ethers';

const contractAddr = '0x72b886d09c117654ab7da13a14d603001de0b777';
const contractABI = [/* ABI Details */];
const walletPrivateKey = 'Your wallet private key';
const signer = new ethers.Wallet(walletPrivateKey);

const token = new Contract(contractAddr, contractABI, signer);

export async function executePermit(spender: string, value: string, nonce: string, deadline: string, isAllowed: boolean): Promise<void> {
  try {
    const permit = {
      spender: spender,
      value: value,
      nonce: nonce,
      deadline: deadline,
      isAllowed: isAllowed
    };

    const domain = {
      name: 'XDEFI Token',
      version: '1.0.0',
      chainId: 1,
      verifyingContract: '0x72b886d09c117654ab7da13a14d603001de0b777',
      salt: '0x1234567890abcdef',
    };

    const types = {
      Permit: [
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' },
        { name: 'isAllowed', type: 'bool' },
      ],
    };

    const signature = await signer._signTypedData(domain, types, permit);
    const { v, r, s } = ethers.utils.splitSignature(signature);

    const permitData = {
      ...permit,
      v,
      r,
      s,
    };

    await token.permit(spender, Number(value), Number(deadline), v, r, s, isAllowed);
  } catch (error) {
    console.error("Permit failed", error);
  }
}