<template>
  <div>
    <div class="row">
      <div class="col" v-if="chartToken">
        <base-button @click="refreshChart" ><i class="tim-icons icon-refresh-01"></i></base-button>
        <base-button @click="chartToken = null" ><i class="tim-icons icon-simple-remove"></i></base-button>
        <div class="text-center" style="overflow-y: scroll; height: 810px;" v-if="chartRefresh">
          <iframe :src="`https://dexscreener.com/ethereum/${chartToken}`"
            frameborder="0" width="100%" height="800px"></iframe>
        </div>

      </div>
    </div>
    <input type="file" @change="tryImportWallets" class="form" accept="application/JSON"
      style="width: 120px; font-size: 10px;" v-if="wallets.length == 0" />
    <div class="row mt-5" v-if="wallets.length == 0">
      <div class="col-3">
        <p class="text-danger">if you dont have a file yet you can set up your wallets file here after submitting all the
          info for a wallet press + it will add it when your done download the file and you'll be using this file next
          time </p>
      </div>
      <div class="col-4">
        <base-input type="password" class="mb-5" placeholder="encryption password" v-model="enc"></base-input>

        <base-input type="text" placeholder="name" v-model="name"></base-input>
        <base-input type="text" placeholder="address" v-model="add"></base-input>
        <base-input type="password" placeholder="private" v-model="priv"></base-input>
        <base-button @click="addWallet">+</base-button>
        <a href="" id="downloadAnchorElem">download</a>

        <p v-for="p in preWallets" :key="p.address"> {{ p.address }}</p>
      </div>
    </div>
    <br>
    <div v-if="wallets.length > 0">
      <base-button @click="guiRefresh = !guiRefresh">double click to reset all wallets</base-button>
      <base-button @click="refreshGas">{{ currentGwei }}</base-button>

    </div>

    <div class="row" v-if="guiRefresh">
      <div class="col-4" v-for="w in wallets" :key="w.address">
        <h4 class="mt-5 mb-0">{{ w.name }}</h4>
        <br>
        <EasySwapVue :_address="w.address" :_private="w.private" />
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
  data() {
    return {
      chartToken: "",
      guiRefresh: true,
      enc: "",
      name: "",
      add: "",
      priv: "",
      wallets: [],
      preWallets: [],
      currentGwei: 0,
      web3: null,
      chartRefresh: true,
    }
  },
  computed: {

  },
  methods: {
    openChart(address){
      this.chartToken = address;
    },
    closeChart(){
      this.chartToken = null
    },
    refreshChart(){
      this.chartRefresh = !this.chartRefresh;
      setTimeout(() => {
        this.chartRefresh = !this.chartRefresh;
      }, 100);
      
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
          console.log(content)
          const decryptedText = this.$CryptoJS.AES.decrypt(content, "_1_" + this.enc).toString(this.$CryptoJS.enc.Utf8)
          console.log(decryptedText)
          var intern = JSON.parse(decryptedText); // Array of Objects.
          console.log(intern); // You can index every object
          this.wallets = intern;
          // this.showWallet(this.wallets[0].address)

        } catch (e) {
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

      console.log(e);
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
