<template>
  <div class="container">
    <div v-if="token.name">
      <h5>{{ token.name }} / {{ token.symbol }}</h5>
      <h5>total supply: {{ token.totalSupply }}</h5>
      <h5>decimals: {{ token.decimals }} </h5>
    </div>

    <base-input :label="`token address`" placeholder="token address" @click="pasteContract" v-model="token_address">

    </base-input>

    <div class="row d-flex align-items-center my-3">
      <div class="col-5">
        <base-input :label="`Max TX`" placeholder="Max TX" v-model="max_tx" @change="changeMaxTxTokens"></base-input>
      </div>
      <div class="col-2">
        <base-button type="primary" class="" @click="getMaxTxPrice()" :disabled="max_tx <= 0" fill>Check price</base-button>
      </div>
      <div class="col-2">
        {{ valueEth }} ETH
      </div>
      <div class="col-3">
        <base-input type="number" min="0" :label="`token % `" placeholder="token %" v-model="max_tx_percent"
          @change="changeMaxTxPercent">
        </base-input>
      </div>
    </div>


    <div class="easyswapcontainer d-flex align-items-center my-3 row">
      <div class="col-10">
        <base-input v-for="(r, i) in recipients" :key="i" :label="`recipient ${i + 1}`" placeholder="recipients"
          v-model="recipients[i]">
        </base-input>
      </div>
      <div class="col-2"><button @click="addRecipients">Add Recipient </button></div>
    </div>

    <div class="row">
      <div class="col-6">
        <base-input :label="`min tax swap`" type="number" min="0" placeholder="min tax swap" v-model="minTxSwap">
        </base-input> <small class="text-danger">min token amount to sell for the ca to dump with you</small>
      </div>
      <div class="col-6">
        <base-input :label="`max tax swap`" type="number" min="0" placeholder="max tax swap" v-model="maxTxSwap">
        </base-input> <small class="text-danger">max token amount that the contract can sell per sell</small>
      </div>
    </div>


    <div class="row" v-if="recipients.length > 0 && recipients[0] != ''">
      <h4 class="text-success">tokens will be sent to these wallets:</h4><br>
    </div>
    <div class="row">
      <div class="col" v-for="rec, i in recipients" :key="i">
        <p class="text-success">{{ rec }}</p>
      </div>
    </div>

  </div>

</template>
<script>
import Web3 from "web3";
import DumBotABI from "@/ABIS/DumBotABI.json";
import TokenABI from "@/ABIS/Token.json";
import UniswapABI from "@/ABIS/UniswapABI.json"

import loading from "@/pages/custom_components/loading.vue";
import { ethers, BigNumber, providers, Transaction, FixedNumber } from "ethers";
import { Network, Alchemy } from 'alchemy-sdk';

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
      recipients: [""],
      alchemy: new Alchemy({ apiKey: "0mzc_JvS6nm4TuDnUbkN3jcW0V2gKnBY", network: Network.ETH_MAINNET }),
      infoTx: "",
      txAvailable: "",
      isLoading: false,
      walletBalance: "",
      max_tx: 0,
      max_tx_percent: 0,
      minTxSwap: 0,
      maxTxSwap: 0,
      valueEth: 0,
      currentTokenBalanceInEth: 0,
      token_address: "",
      token: { name: '', decimals: '', totalSupply: 0 },
      web3: null,
      currentTokenBalance: 0,
      dumbotAddress: "0x53680a4107a70695b5BAf0AfBBbaB783d9f7b1c1",
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      nonce: 0,
      wallet: null,
      httpsProvider: "",
      token: {},
      walletAddress: "",
      uniswapRouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",

    }
  },
  computed: {},
  methods: {
    async getMaxTxPrice() {
      try {
        var contract = new this.web3.eth.Contract(TokenABI, this.token_address)
        let tokensWithDecimals = BigNumber.from(this.max_tx).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
        contract = new this.web3.eth.Contract(UniswapABI, this.uniswapRouterAddress, { from: this.walletAddress });
        let value_in_eth = await contract.methods.getAmountsOut(
          tokensWithDecimals,
          [this.token_address, this.weth_address]
        ).call();
        tokensWithDecimals = value_in_eth.length >= 0 ? value_in_eth[1] : 0;
        console.log(ethers.utils.formatEther(value_in_eth[1]))
        this.valueEth = ethers.utils.formatEther(value_in_eth[1]);
      } catch (e) {
        console.error(e)
        this.$notify({
          type: "danger",
          timeout: 1500,
          message: e.toString()
        });

        return 0;
      }
    },
    async pasteContract() {
      this.token_address = await navigator.clipboard.readText();
      await this.getContractInfo();

    },
    changeMaxTxPercent() {
      console.log(this.max_tx_percent)
      if (!this.token.name) {
        return
      }
      this.max_tx = this.token.totalSupply * this.max_tx_percent / 100;
      this.getMaxTxPrice();
    },
    changeMaxTxTokens() {
      this.max_tx_percent = 0;
    },
    async getContractInfo() {
      try {
        let contract = new this.web3.eth.Contract(TokenABI, this.token_address);
        let name = await contract.methods.name().call();
        let symbol = await contract.methods.symbol().call();
        let decimals = await contract.methods.decimals().call();
        let totalSupply = await contract.methods.totalSupply().call();
        this.token = {
          name: name,
          symbol: symbol,
          decimals: decimals,
          totalSupply: totalSupply / Math.pow(10, decimals),
          totalSupplyWithDecimals: totalSupply
        }
      } catch (e) {
        console.warn(e.toString())
        this.$notify({
          type: "danger",
          timeout: 1500,
          message: e.toString()
        });
      }
    },
    addRecipients() {
      this.recipients.push("")
    },
    async sendTx(from, gasLimit, gasPrice, to, value, data, priv) {
      let contract = this.web3.eth.Contract(DumBotABI, this.dumbotAddress, { from: this.walletAddress });
      var data = contract.methods.DumpnBuyRepeat(amountMin._hex, [this.weth_address, this.token_address]);

      let nonce = await this.web3.eth.getTransactionCount(from);
      let wallet = new ethers.Wallet(priv.toString('hex'), this.httpsProvider);
      let rawTransaction = {
        "from": from,
        "gasLimit": gasLimit,
        "gasPrice": gasPrice,
        "to": to,
        "value": value,
        "data": data,
        "nonce": nonce,
      };
      console.log(rawTransaction)
      const signedTx = await wallet.signTransaction(rawTransaction);
      const txHash = ethers.utils.keccak256(signedTx);
      this.infoTx += `\netherscan.io/tx/${txHash}`;
      let tx = await this.httpsProvider.sendTransaction(signedTx);
      console.log(tx)
    },

    async getCurrentNonce(address) {
      this.nonce = await this.web3.eth.getTransactionCount(address);
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

    async getWalletBalance(address) {
      this.isLoading = true;
      this.walletBalance = await this.httpsProvider.getBalance(address);
      this.walletBalance /= Math.pow(10, 18);
      this.walletBalance = this.walletBalance.toFixed(2)
      this.isLoading = false;
    },

  },
  mounted() {
    let publicNode = "https://uk.rpc.blxrbdn.com";
    this.web3 = new Web3(publicNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(publicNode);
    this.info(`using ${publicNode}`)
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
