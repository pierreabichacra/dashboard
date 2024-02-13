<template>
  <div class="easyswapcontainer">
    <h1>DOESNT WORK!!!!</h1>
    <small style="cursor: pointer;" @click="getWalletBalance(_address)" v-if="walletBalance">{{ walletBalance }} eth
      <a :href="txAvailable" v-if="txAvailable" target="_blank">TX</a>
      <loading v-if="isLoading" />
    </small>
    <p>
      <button v-if="token.decimals" style="background-color: red; padding: 5px; cursor: pointer;"
        @click="getQuotes">R</button>
        <button class="btn btn-warning" @click="v3Fee = '3000'">.3%</button>
        <button class="btn btn-warning" @click="v3Fee = '10000'">1%</button>
      <base-input :label="token.name == '' ? '' : token.name + '/' + token.symbol + ': ' + token.decimals"
        placeholder="contract address" @click="pasteContract" v-model="targetContract"></base-input>
    </p>
    <p>
      {{ eth_amount_to_send }} ETH
      <base-input placeholder="Eth amount to send" type="number" step="0.01" v-model="eth_amount_to_send"
        @change="getQuotes"></base-input>
    </p>
    <p>
      <small>{{ this.real_token_amount_to_receive - (this.real_token_amount_to_receive * (this.slippage / 100)) }} {{ token.symbol }}</small>
      <base-input type="number" placeholder="token amount to receive" v-model="token_amount_to_receive"></base-input>
    </p>
    <p>
      <base-button type="warning" @click="executeBuy" fill>Buy</base-button>
      <base-button type="info" @click="approveToken" fill>Approve</base-button>
      <base-button type="danger" @click="cancelTx" title="canceling tx always takes 1 gwei higher than set gwei"
        fill>Cancel TX</base-button>
    </p>
    <div class="row">
      <div class="col">
        <base-button type="primary" @click="saveProfile" fill>save</base-button>
        <base-button type="danger" @click="deleteProfile" fill>del</base-button>
        <base-input label="Slippage" title="Slippage" placeholder="slippage" type="number" max="100"
          v-model="slippage"></base-input>
        {{ slippage }}
      </div>
      <div class="col">

        <base-input label="GWEI" title="GWEI" placeholder="gwei" type="number" step="5" min="0" max="100"
          v-model="gwei"></base-input>
        <base-input label="Gas Limit" title="Gas Limit" placeholder="Gas Limit" type="number" step="5000" min="0"
          v-model="gasLimit"></base-input>
        <button @click="getQuotes">getQuotes</button>
      </div>
    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import loading from "@/pages/custom_components/loading.vue";
import TokenAbi from "@/ABIS/Token.json";
import UniversalRouter from "@/ABIS/UniversalRouter.json"
import UniswapSwapRouterABI from "@/ABIS/UniswapSwapRouterABI.json"
import { ethers, BigNumber, providers, Transaction, FixedNumber } from "ethers";
import { ChainId, Token, WETH, Fetcher, Route, Trade, TradeType, Percent } from '@uniswap/sdk';
import QuoterAbi from "@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json"
import Quoter2Abi from "@uniswap/v3-periphery/artifacts/contracts/lens/QuoterV2.sol/QuoterV2.json"

export default {
  components: { loading },
  props: {
    _address: {
      type: String,
    },
    _private: {
      type: String,
    },
  },
  data() {
    return {
      eth_amount_to_send: 0,
      token_amount_to_receive: 0,
      real_token_amount_to_receive: 0,
      hex_value_to_send: "",

      autoRefreshId: null,
      txAvailable: "",
      isLoading: false,
      walletBalance: "",
      slippage: 5,
      token_number_to_sell: 0,
      currentTokenBalanceInEth: 0,
      wallets: [],
      targetContract: "",
      token: { name: '', decimals: '', totalSupply: 0 },
      web3: null,
      currentTokenBalance: 0,
      gwei: 45,
      gasLimit: 750000,
      universalUniswapRouterAddress: "0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B",
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      uniswapSwapRouterAddress: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      quoterAddress: "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",
      quoter2Address: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
      nonce: 0,
      wallet: null,
      httpsProvider: "https://rpc.mevblocker.io/",
      v3Fee: '3000',
    }
  },
  computed: {},
  methods: {
    async getQuotes() {
      let start = Date.now();
      this.isLoading = true;
      const provider = this.httpsProvider;
      const tokenIn = this.weth_address;
      const tokenOut = this.targetContract;
      const fee = this.v3Fee;
      const amountIn = ethers.utils.parseEther(this.eth_amount_to_send);
      const sqrtPriceLimitX96 = '0';
      console.log(QuoterAbi)
      const quoter = new ethers.Contract(
        this.quoterAddress,
        QuoterAbi.abi,
        provider
      )
      const quoter2 = new ethers.Contract(
        this.quoter2Address,
        Quoter2Abi.abi,
        provider
      )

      const amountOut = await quoter.callStatic.quoteExactInputSingle(
        tokenIn,
        tokenOut,
        fee,
        amountIn,
        sqrtPriceLimitX96
      )
      console.log(
        "amountOut",
        ethers.utils.formatUnits(amountOut.toString(), this.token.decimals)
      );

      const params = {
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: fee,
        amountIn: amountIn,
        sqrtPriceLimitX96: sqrtPriceLimitX96
      }
      const output = await quoter2.callStatic.quoteExactInputSingle(params);

      console.log(
        'amountOut',
        ethers.utils.formatUnits(output.amountOut.toString(), this.token.decimals)
      )
      this.token_amount_to_receive = ethers.utils.formatUnits(output.amountOut.toString(), this.token.decimals);
      this.real_token_amount_to_receive = output.amountOut.toString();
      console.log('sqrt after', output.sqrtPriceX96After.toString())
      console.log('init ticks crossed', output.initializedTicksCrossed.toString());
      console.log('gasEstimate', output.gasEstimate.toString());
      this.isLoading = false;
      let end = Date.now();
      console.log(`get quotes too ${end - start}ms to execute`)
    },
    async executeBuy() {

      const tokenAddress = this.targetContract.toLowerCase(); // Replace with the token address
      const routerAddress = this.uniswapSwapRouterAddress; // Uniswap router address

      // Swap parameters
      const slippageTolerance = this.slippage; // Slippage tolerance percentage (0.5% in this case)

      // Get the amount of token required for the desired ETH amount
      const amountIn = ethers.utils.parseEther(this.eth_amount_to_send.toString());

      // Create a swap transaction
      const routerABI = UniswapSwapRouterABI; // Replace with the correct ABI file path
      const routerContract = new this.web3.eth.Contract(routerABI, routerAddress);
      const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10 minutes from now

      let x = this.real_token_amount_to_receive - (this.real_token_amount_to_receive * (this.slippage / 100))
      let smallNum = BigNumber.from(this.real_token_amount_to_receive).div(BigNumber.from(10).pow(this.token.decimals))
      smallNum = smallNum - (smallNum * (slippageTolerance / 100));
      smallNum = smallNum.toFixed(0);
      smallNum = BigNumber.from(smallNum).mul(BigNumber.from(10).pow(this.token.decimals))
      console.log(smallNum)

      const amountOutMin = smallNum;
      // let amountOutMin = BigNumber.from(x)
      console.log(amountOutMin)
      const path = [this.weth_address, tokenAddress];
      const to = this._address; // Replace with your wallet address

      const swapTransaction = routerContract.methods.exactInputSingle({
        tokenIn: path[0],
        tokenOut: path[1],
        fee: this.v3Fee, // Use the desired fee (3000 for 0.3% fee)
        recipient: to,
        deadline: deadline,
        amountIn: amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: '0',
      });
      console.log(swapTransaction)
      var count = await this.getCurrentNonce();

      let rawTransaction = {
        from: this._address,
        to: routerAddress,
        data: swapTransaction.encodeABI(),
        "value": (amountIn)._hex,
        "gasPrice": BigNumber.from(this.gwei).mul(BigNumber.from(10).pow(9))._hex,
        "gasLimit": BigNumber.from(this.gasLimit)._hex,
        "nonce": this.web3.utils.toHex(count)
      };
      console.log(rawTransaction, amountIn, amountOutMin);
      let res = await this.signAndSendType0Transaction(rawTransaction);


    },

    async executeSell() {
      try {
        const contractAddress = '0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B'; // Router contract address
        const contractABI = []; // Add the ABI of the Router contract here

        const routerContract = new ethers.Contract(contractAddress, contractABI, this.signer);

        const tokenIn = 'YOUR_TOKEN_ADDRESS'; // Token address
        const tokenOut = ethers.constants.AddressZero; // ETH
        const amountIn = ethers.utils.parseEther('100'); // Token amount in wei
        const amountOutMinimum = ethers.utils.parseEther('0.1'); // Minimum ETH amount in wei
        const recipient = await this.signer.getAddress();
        const deadline = Math.floor(Date.now() / 1000) + 600; // 10-minute deadline

        const path = [tokenIn, tokenOut];

        const options = {
          path,
          recipient,
          deadline,
          amountIn,
          amountOutMinimum,
          sqrtPriceLimitX96: 0,
        };

        await routerContract.swapExactTokensForETH(
          options.amountIn,
          options.amountOutMinimum,
          options.path,
          options.recipient,
          options.deadline,
          { gasLimit: 2000000, gasPrice: 0 }
        );

        console.log('Token sold successfully!');
      } catch (error) {
        console.error('An error occurred:', error);
      }
    },

    async sendTx() {
      this.isLoading = true;
      let count = await this.getCurrentNonce();
      var amountToBuyWith = this.web3.utils.toWei(`${this.eth_amount_to_send}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);

      let rawTransaction = {
        "from": this._address,
        "gasPrice": BigNumber.from(this.gwei).mul(BigNumber.from(10).pow(9))._hex,
        "gasLimit": BigNumber.from(this.gasLimit)._hex,
        "to": this.targetContract,
        "value": amountToBuyWith._hex,
        "data": this.hex_value_to_send,
        "nonce": this.web3.utils.toHex(count)
      };
      console.log(rawTransaction)
      let res = await this.signAndSendType0Transaction(rawTransaction);
      console.log(res);
      this.txAvailable = "https://etherscan.io/tx/" + res.hash;
      this.isLoading = false;

    },
    async cancelTx() {
      let count = await this.getCurrentNonce();
      var amountToBuyWith = this.web3.utils.toWei(`${this.eth_amount_to_send}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);
      let gwei = Number(this.gwei) + 10;
      console.log(gwei)
      let rawTransaction = {
        "from": this._address,
        "gasPrice": BigNumber.from(gwei).mul(BigNumber.from(10).pow(9))._hex,
        "gasLimit": BigNumber.from(this.gasLimit)._hex,
        "to": this._address,
        "data": "0x00",
        "nonce": this.web3.utils.toHex(count)
      };
      console.log(rawTransaction)
      let res = await this.signAndSendType0Transaction(rawTransaction);
      console.log(res);
    },
    saveProfile() {
      let profile = {
        gasLimit: this.gasLimit,
        gwei: this.gwei,
        slippage: this.slippage,
      }
      localStorage.setItem("profile", JSON.stringify(profile));
    },
    deleteProfile() {
      console.log(localStorage.getItem("profile"))
      localStorage.removeItem('profile');
    },
    async signAndSendType0Transaction(rawTransaction) {
      try {
        let tx = rawTransaction;
        tx.chainId = 1;

        const signedTx = await this.wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.txAvailable = `https://etherscan.io/tx/${txHash}`
        return await this.httpsProvider.sendTransaction(signedTx);
      } catch (e) {
        console.warn(e);
      }
    },
    async pasteContract() {
      this.targetContract = await navigator.clipboard.readText();
      this.info(`target contract set to: ${this.targetContract}`)
      await this.getCaInfo(this.targetContract);
    },
    async getCaInfo(ca) {
      try {
        let start =  Date.now();
        let contract = new this.web3.eth.Contract(TokenAbi, ca);
        let name = await contract.methods.name().call();
        let symbol = await contract.methods.symbol().call();
        let decimals = await contract.methods.decimals().call();
        let totalSupply = await contract.methods.totalSupply().call();
        this.token = {
          name: name,
          symbol: symbol,
          decimals: decimals,
          totalSupply: totalSupply / Math.pow(10, decimals)
        }
        let end =  Date.now();
        console.log(`get ca info took ${end - start}ms to execute`)
      } catch (e) {
        console.warn(e.toString())
      }
    },
    async getCurrentNonce() {
      if (!this._address) {
        danger("wallet not attached")
        return;
      }
      this.nonce = await this.web3.eth.getTransactionCount(this._address);
      return this.nonce;
    },
    danger(text) {
      this.$notify({
        type: "danger",
        timeout: 2000,
        message: text
      });
    },
    info(text) {
      this.$notify({
        type: "info",
        timeout: 2000,
        message: text
      });
    },

    tryImportProfile() {
      let profile = JSON.parse(localStorage.getItem("profile"));
      if (profile) {
        console.log(profile)
        this.gwei = profile.gwei;
        this.gasLimit = profile.gasLimit;
        this.slippage = profile.slippage;
      }

    },
    async getWalletBalance(address) {
      this.isLoading = true;
      this.walletBalance = await this.httpsProvider.getBalance(address);
      this.walletBalance /= Math.pow(10, 18);
      this.walletBalance = this.walletBalance.toFixed(2)
      this.isLoading = false;
    },
    async approveToken() {
      this.isLoading = true;
      var contract = new this.web3.eth.Contract(TokenAbi, this.targetContract, { from: this._address });
      let maxAmountToApprove = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
      var data = contract.methods.approve(
        this.uniswapRouterAddress,
        maxAmountToApprove
      );
      var count = await this.getCurrentNonce();
      var rawTransaction = {
        "from": this._address,
        "gasPrice": BigNumber.from(this.gwei).mul(BigNumber.from(10).pow(9))._hex,
        "gasLimit": BigNumber.from(this.gasLimit)._hex,
        "to": this.targetContract,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      try {
        const signedTx = await this.wallet.signTransaction(rawTransaction);
        let res = await this.httpsProvider.sendTransaction(signedTx);
        this.txAvailable = `https://etherscan.io/tx/${res.hash}`
        console.log(res)
        this.isLoading = false;
      } catch (e) {
        console.error(e)
      }

    },
  },
  mounted() {
    let publicNode = "https://rpc.mevblocker.io/";
    this.web3 = new Web3(publicNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(publicNode);
    this.wallet = new ethers.Wallet(this._private.toString('hex'), this.httpsProvider);
    this.info(`using ${publicNode}`)
    this.getWalletBalance(this._address);
    this.tryImportProfile();
  },
  beforeDestroy() {

  }
};
</script>
<style>
.easyswapcontainer {
  border: 1px solid grey;
  border-radius: 25px;
  padding: 2%;
}
</style>
