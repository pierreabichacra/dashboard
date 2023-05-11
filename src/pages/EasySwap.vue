<template>
  <div class="easyswapcontainer">
    <small style="cursor: pointer;" @click="getWalletBalance(_address)" v-if="walletBalance">{{ walletBalance }} eth
      <i class="tim-icons icon-chart-bar-32 mx-3 my-2 pb-1" style="cursor: pointer;" v-if="token.decimals" @click="showChart"></i>
      <a :href="txAvailable" v-if="txAvailable" target="_blank">TX</a>
      <loading v-if="isLoading" />
    </small>
    <p>
      <base-input
        :label="`${token.warn ? 'you dont have shit jeet' : (token.symbol ? token.name + ' / ' + token.symbol : '')}`"
        placeholder="contract address" @click="pasteContract" v-model="targetContract"></base-input>
    </p>
    <p>
      <small v-if="token.decimals">{{ token.decimals }} decimals <span style="color: greenyellow">{{ token_number_to_sell
      }}</span></small>
      <base-input type="number" placeholder="token balance" :value="tokenNumberToSee"
        @change="changeSellTokenAMount"></base-input>
    </p>
    <p>
      <base-input placeholder="eth value" v-model="currentTokenBalanceInEth"></base-input>
    </p>
    <p>
      <base-button type="warning" @click="sellTokenAmount" fill>swap</base-button>
      <base-button type="success" @click="max" fill>max</base-button>
      <base-button type="primary" @click="refreshTokensPrice" fill><i class="tim-icons icon-refresh-01"></i></base-button>
      <base-button type="danger" @click="stopAutoRefresh" v-if="autoRefreshId" fill>S.A.R</base-button>
      <base-button type="success" @click="startAutoRefresh" v-if="!autoRefreshId && this.token.decimals" fill>S.A.R</base-button>
      <base-button type="primary" @click="approveToken" fill>approve</base-button>
    </p>
    <div class="row">
      <div class="col">
        <base-input label="Slippage" title="Slippage" placeholder="Slippage" type="number" step="5" min="0" max="100"
          v-model="slippage"></base-input>
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
  computed: {
    tokenNumberToSee() {
      return this.token_number_to_sell / Math.pow(10, this.token.decimals)
    }
  },
  methods: {
    showChart(){
      this.$parent.openChart(this.targetContract)
    },
    stopAutoRefresh() {
      clearInterval(this.autoRefreshId);
      this.autoRefreshId = null;
    },
    startAutoRefresh() {
      let self = this;
      this.autoRefreshId = setInterval(() => {
        self.refreshTokensPrice();
      }, 3000);
    },
    saveProfile() {
      let profile = {
        gasLimit: this.gasLimit,
        gwei: this.gwei,
        slippage: this.slippage,
      }
      console.log(profile)
      localStorage.setItem("profile", JSON.stringify(profile));
    },
    deleteProfile() {
      console.log(localStorage.getItem("profile"))
      localStorage.removeItem('profile');

    },
    async changeSellTokenAMount(e) {
      console.log(e.target.value)
      let toMult = BigNumber.from(BigNumber.from(10).pow(this.token.decimals))
      this.token_number_to_sell = BigNumber.from(e.target.value).mul(toMult);
      this.currentTokenBalanceInEth = 0;
      await this.refreshTokensPrice()
    },
    async signAndSendType0Transaction(rawTransaction) {

      try {
        let tx = rawTransaction;
        tx.chainId = 1;

        const signedTx = await this.wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.printLinkToConsole(txHash);
        await this.httpsProvider.sendTransaction(signedTx);

        this.printTextToConsole("tx mined")
      } catch (e) {
        console.warn(e);
        this.printTextToConsole(`Tx errored:  ${e.toString()}`);
      }
    },
    async max() {
      if (this.targetContract) {
        this.getCaInfo(this.targetContract);
        this.token_number_to_sell = this.currentTokenBalance;
        await this.getTokenBalance();
      } else {
        this.token.warn = "Contract address needed"
      }
    },
    async getTokenBalance() {
      console.log("getTokenBal")
      try {
        var contract = new this.web3.eth.Contract(TokenAbi, this.targetContract)
        let result = await contract.methods.balanceOf(this._address).call();
        this.currentTokenBalance = result;
        this.token_number_to_sell = result;
        contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress, { from: this.walletAddress });
        let value_in_eth = await contract.methods.getAmountsOut(
          this.currentTokenBalance,
          [this.targetContract, this.weth_address]
        ).call();
        this.currentTokenBalanceInEth = value_in_eth.length >= 0 ? value_in_eth[1] : 0;
        this.currentTokenBalanceInEth = this.currentTokenBalanceInEth / Math.pow(10, 18)
        console.log(value_in_eth)
        this.token.warn = null;
        return result;
      } catch (e) {
        this.token.warn = "you dont have shit jeet"
        console.error(e)
        return 0;
      }

    },
    async refreshTokensPrice() {
      try {
        console.log("refresh tkn price")
        var contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress, { from: this.walletAddress });
        let amountToSell = BigNumber.from(this.token_number_to_sell);
        console.log(this.token_number_to_sell)
        let value_in_eth = await contract.methods.getAmountsOut(
          amountToSell._hex,
          [this.targetContract, this.weth_address]
        ).call();
        console.log(value_in_eth)
        let x = value_in_eth.length >= 0 ? value_in_eth[1] : 0;
        this.currentTokenBalanceInEth = x / Math.pow(10, 18)
        this.token.warn = null;
      } catch (e) {
        this.token.warn = "Balance 0"
        console.warn(e)
        return 0;
      }
    },
    async approveToken() {
      var contract = new this.web3.eth.Contract(TokenAbi, this.targetContract, { from: this._address });
      let maxAmountToApprove = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
      var data = contract.methods.approve(
        this.uniswapRouterAddress,
        maxAmountToApprove
      );
      console.log(data)
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
        this.isLoading = true;
        let res = await this.httpsProvider.sendTransaction(signedTx);
        this.txAvailable = `https://etherscan.io/tx/${res.hash}`
        console.log(res)
        this.isLoading = false;
      } catch (e) {
        console.error(e)
      }

    },
    async getCaInfo(ca) {
      try {
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
      } catch (e) {
        console.warn(e.toString())
      }
    },
    async pasteContract() {
      this.targetContract = await navigator.clipboard.readText();
      this.getCaInfo(this.targetContract);

    },
    async sellTokenAmount() {
      this.txAvailable = ``;
      let token_to_sell = this.targetContract;
      let token_number_to_sell_BigNum = BigNumber.from(this.token_number_to_sell);
      let eth_to_receive = (this.currentTokenBalanceInEth)
      if (this.slippage < 100) {
        eth_to_receive = eth_to_receive - (eth_to_receive * this.slippage) / 100;
      }else{
        eth_to_receive = 0;
      }
      eth_to_receive = eth_to_receive.toFixed(6)

      console.log(eth_to_receive)
      eth_to_receive = ethers.utils.parseEther(eth_to_receive.toString())
      console.log(eth_to_receive)
      var contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress, { from: this._address });
      var data = contract.methods.swapExactTokensForETHSupportingFeeOnTransferTokens(
        token_number_to_sell_BigNum._hex,
        eth_to_receive._hex,
        [token_to_sell, this.weth_address],
        this._address,
        this.web3.utils.toHex(Math.round(Date.now() / 1000) + 60 * 20),
      );

      var count = await this.getCurrentNonce();
      var rawTransaction = {
        "from": this._address,
        "gasPrice": BigNumber.from(this.gwei).mul(BigNumber.from(10).pow(9))._hex,
        "gasLimit": BigNumber.from(this.gasLimit)._hex,
        "to": this.uniswapRouterAddress,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      console.log(`token number to sell: ${token_number_to_sell_BigNum}\n eth: ${eth_to_receive}`)
      console.log(rawTransaction)

      try {
        const signedTx = await this.wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.isLoading = true;
        let res = await this.httpsProvider.sendTransaction(signedTx);
        this.txAvailable = `https://etherscan.io/tx/${res.hash}`
        console.log(res)
        this.isLoading = false;
      } catch (e) {
        console.error(e)
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
        timeout: 3000,
        message: text
      });
    },

    async tryImportWallets(e) {
      let file_to_read = e.target.files[0];
      var fileread = new FileReader();
      fileread.onload = (e) => {
        var content = e.target.result;
        var intern = JSON.parse(content); // Array of Objects.
        console.log(intern); // You can index every object
        this.wallets = intern;
        this.showWallet(this.wallets[0].address)
      };
      fileread.readAsText(file_to_read);

      console.log(e);
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
  },
  mounted() {
    let cNode = "https://eth-mainnet.g.alchemy.com/v2/0mzc_JvS6nm4TuDnUbkN3jcW0V2gKnBY";
    this.web3 = new Web3(cNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(cNode);
    this.wallet = new ethers.Wallet(this._private.toString('hex'), this.httpsProvider);
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
