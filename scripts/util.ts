import fs from 'fs';
import hre from 'hardhat';

export const writeAddr = (addressFile: string, network: string, addr: string, name: string) => {
  fs.appendFileSync(
    addressFile,
    `${name}: [https://${network}.polygonscan.com/address/${addr}](https://${network}.polygonscan.io/address/${addr})<br/>`
  );
};

export const verify = async (addr: string, args: any[]) => {
  try {
    await hre.run('verify:verify', {
      address: addr,
      constructorArguments: args,
    });
  } catch (ex: any) {
    if (ex.toString().indexOf('Already Verified') == -1) {
      throw ex;
    }
  }
};
