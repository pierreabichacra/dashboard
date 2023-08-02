<template>
  <div>   
    <br>
    <div class="row" v-if="wallets.length > 0">
      <base-button @click="guiRefresh = !guiRefresh">double click to reset all wallets</base-button>
      <base-button @click="trackedProject +=1">+ [token]</base-button>
      <base-button @click="refreshGas">{{ currentGwei }}</base-button>
      <div class="row">
        <div class="col">
          <base-input type="text" placeholder="token address" v-model="token_address"
            style="width: 30%; float: right;" @click="pasteContract"></base-input>
        </div>
        <div class="col">
          <base-button @click="checkWalletsContainingTokenAddress">
          <i class="tim-icons icon-zoom-split"></i>
        </base-button>
          <base-button @click="refreshWallets">
          <i class="tim-icons icon-refresh-02"></i>
        </base-button>

        </div>
      </div>
    </div>
    <div v-for="t in trackedProject" :key="t">
      <div class="row" v-if="guiRefresh">
      <div class="col-4" v-for="w in wallets" :key="w.address">
        <h5 class="mt-5 mb-0" v-if="token_owners.includes(w.address)"><a target="_blank" :href="`https://etherscan.io/address/${w.address}`">{{ w.name }}</a>
        </h5>
        <br>
        <EasySwapVue :_address="w.address" :_private="w.private" v-if="token_owners.includes(w.address)" :currentToken="token_owners.includes(w.address) ? token_address : null"/>
      </div>
    </div>
    </div>
   
  </div>
</template>
<script>
import loading from "@/pages/custom_components/loading.vue";
import EasySwapVue from './EasySwap.vue';
import Web3 from "web3";

export default {
  components: { loading, EasySwapVue },
  props: {
    wallets: {type: Array}
  },
  data() {
    return {
      trackedProject: 1,
      chartToken: "",
      guiRefresh: true,
      enc: "",
      name: "",
      add: "",
      priv: "",
      preWallets: [],
      currentGwei: 0,
      web3: null,
      chartRefresh: true,
      token_address: "",
      token_owners: [],
    }
  },
  computed: {

  },
  methods: {
    openChart(address) {
      this.chartToken = address;
    },
    closeChart() {
      this.chartToken = null
    },

    async pasteContract() {
      this.token_address = await navigator.clipboard.readText();
      await this.checkWalletsContainingTokenAddress();
    },

    refreshChart() {
      this.chartRefresh = !this.chartRefresh;
      setTimeout(() => {
        this.chartRefresh = !this.chartRefresh;
      }, 100);

    },
    refreshWallets(){
      this.token_owners = this.wallets.map(x=> {return x.address})
      console.log(this.token_owners)
      this.token_address = ""
    },
    async checkWalletsContainingTokenAddress() {
      let minABI = [
        // balanceOf
        {
          "constant": true,
          "inputs": [{ "name": "_owner", "type": "address" }],
          "name": "balanceOf",
          "outputs": [{ "name": "balance", "type": "uint256" }],
          "type": "function"
        },
        // decimals
        {
          "constant": true,
          "inputs": [],
          "name": "decimals",
          "outputs": [{ "name": "", "type": "uint8" }],
          "type": "function"
        }
      ];
      let contract_address = this.token_address;
      let adresses_to_check = this.wallets.map(x => { return x.address });
      console.log(adresses_to_check)
      let contract = new this.web3.eth.Contract(minABI, contract_address);
      let owners = [];
      for (let i = 0; i < adresses_to_check.length; i++) {
        let addy = adresses_to_check[i];
        let balance = await contract.methods.balanceOf(addy).call();
        if (balance > 0) {
          owners.push(addy);
        }
      }
      this.token_owners = owners;
    },
    async refreshGas() {
      let cNode = "https://eth-mainnet.g.alchemy.com/v2/0mzc_JvS6nm4TuDnUbkN3jcW0V2gKnBY";
      this.web3 = new Web3(cNode);
      this.currentGwei = 0;
      let gas = await this.web3.eth.getGasPrice();
      this.currentGwei = Math.ceil(gas / Math.pow(10, 9));
    },
    addWallet() {
      this.preWallets.push({ name: this.name, address: this.add, private: this.priv });
      let encrypted = this.CryptoJS.AES.encrypt(JSON.stringify(this.preWallets), "_1_" + this.enc).toString();
      var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(encrypted);
      var dlAnchorElem = document.getElementById('downloadAnchorElem');
      dlAnchorElem.setAttribute("href", dataStr);
      dlAnchorElem.setAttribute("download", "myShit.json");
    },
    async tryImportWallets(e) {
      console.log("try import")
      let file_to_read = e.target.files[0];
      var fileread = new FileReader();
      fileread.onload = (e) => {
        try {
          var content = e.target.result;
          const decryptedText = this.$CryptoJS.AES.decrypt(content, "_1_" + this.enc).toString(this.$CryptoJS.enc.Utf8)
          var intern = JSON.parse(decryptedText); // Array of Objects.
          this.wallets = intern;
          this.refreshWallets();
        } catch (e) {
          console.error(e)
          this.$notify({
            type: "danger",
            timeout: 1500,
            message: "your files are encrypted a password is needed to import them"
          });
          setTimeout(() => {
            window.location.reload();
          }, 1500);
        }
      };
      fileread.readAsText(file_to_read);

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
    this.refreshGas();
    // this.attachNode();
    // this.getCurrentGwei();
    // if (this.privateKey) {
    //   this.attachWallet();
    // } else {
    //   this.walletAddress = this._address;
    //   this.privateKey = this._private;
    //   this.attachWallet();
    // }
  },
  beforeDestroy() {

  }
};
</script>
<style></style>
