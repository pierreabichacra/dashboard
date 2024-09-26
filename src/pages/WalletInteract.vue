<template>
  <div class="easyswapcontainer">
    <small style="cursor: pointer;" @click="getWalletBalance(_address)" v-if="walletBalance">{{ walletBalance }} eth
      <a :href="txAvailable" v-if="txAvailable" target="_blank">TX</a>
      <loading v-if="isLoading" />
    </small>
    <p>
      <base-input :label="this.targetContract == '' ? '' : this.targetContract" placeholder="contract address"
        @click="pasteContract" v-model="targetContract"></base-input>
    </p>
    <p>
      {{ eth_amount_to_send }}
      <base-input placeholder="Eth amount to send" type="number" step="0.01" v-model="eth_amount_to_send"></base-input>
    </p>
    <p>
      {{ hex_value_to_send }}
      <base-input placeholder="Hex value to send" v-model="hex_value_to_send"></base-input>
    </p>
    <p>
      <base-button type="warning" @click="sendTx" fill>Send TX</base-button>
      <base-button type="danger" @click="cancelTx" title="canceling tx always takes 1 gwei higher than set gwei"
        fill>Cancel TX</base-button>
    </p>
    <div class="row">
      <div class="col">
        <base-button type="primary" @click="saveProfile" fill>save</base-button>
        <base-button type="danger" @click="deleteProfile" fill>del</base-button>
      </div>
      <div class="col">
        <base-input label="GWEI" title="GWEI" placeholder="gwei" type="number" step="5" min="0" max="100"
          v-model="gwei"></base-input>
        <base-input label="Gas Limit" title="Gas Limit" placeholder="Gas Limit" type="number" step="5000" min="0"
          v-model="gasLimit"></base-input>
      </div>
    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import loading from "@/pages/custom_components/loading.vue";
import TokenAbi from "@/ABIS/Token.json";
import UniswapAbi from "@/ABIS/UniswapABI.json";
import { ethers, BigNumber, providers, Transaction } from "ethers";

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
      hex_value_to_send: "",

      autoRefreshId: null,
      txAvailable: "",
      isLoading: false,
      walletBalance: "",
      slippage: 100,
      token_number_to_sell: 0,
      currentTokenBalanceInEth: 0,
      wallets: [],
      targetContract: "",
      token: { name: '', decimals: '', totalSupply: 0 },
      web3: null,
      currentTokenBalance: 0,
      gwei: 75,
      gasLimit: 750000,
      uniswapRouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      nonce: 0,
      wallet: null,
      httpsProvider: null,
    }
  },
  computed: {},
  methods: {
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
    // async test() {
    //   const contractAddress = '0xBD49Aa5Cd48d346ac777deC05a5D413d14297A3b';
    //   this.httpsProvider.getCode(contractAddress).then((bytecode) => {

    //     const functionSignatures = [];

    //     let i = 0;
    //     while (i < bytecode.length - 8) {
    //       const signature = bytecode.slice(i + 10, i + 10 + 8);
    //       console.error(signature)
    //       try {
    //         const decodedSignature = ethers.hexlify(
    //           ethers.utils.defaultAbiCoder.decode(['bytes4'], signature)
    //         );
    //         functionSignatures.push(decodedSignature);
    //       } catch (error) {
    //         // Ignore errors and continue to the next iteration
    //         console.warn(error)
    //       }
    //       i += 2;
    //     }
    //     return functionSignatures;
    //   });
    // },
  },
  mounted() {
    let quickNode = "http://78.46.76.120:8545";
    this.web3 = new Web3(quickNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(quickNode);
    this.wallet = new ethers.Wallet(this._private.toString('hex'), this.httpsProvider);
    this.getWalletBalance(this._address);
    this.tryImportProfile();
    // this.test();
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
