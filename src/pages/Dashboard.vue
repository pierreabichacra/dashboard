<template>
  <div>
    <div class="row">
      <p v-if="wallets.length == 0">
      <input type="file" @change="tryImportWallets" class="form" accept="application/JSON" style="width: 120px; font-size: 10px;" />
      </p>
      <div class="row" v-if="wallets.length == 0">
        <div class="col">
          <base-input type="password" placeholder="password" v-model="enc"></base-input>
        </div>
      </div>
      <div class="col my-2" v-for="w, i in wallets" :key="i">
        <base-button :type="`${selectedWallet == w.address ? 'primary':'secondary'}`" @click="showWallet(w.address)" :title="w.address">{{w.name}}</base-button>
      </div>
    </div>
    <MagmaBot v-for="w, i in wallets" :key="i+'_'" :_address="w.address" :_private="w.private" v-show="selectedWallet == w.address" />
  </div>
</template>
<script>
import MagmaBot from "@/pages/MagmaBot.vue";
export default {
  components: { MagmaBot },
  data() {
    return {
      enc: "",
      selectedWallet: null,
      wallets: [],
    }
  },
  computed: {
    tokensValInEth: function () {}
  },
  methods: {
    async tryImportWallets(e) {
      let file_to_read = e.target.files[0];
      var fileread = new FileReader();
      fileread.onload = (e) => {
        var content = e.target.result;
        const decryptedText = this.$CryptoJS.AES.decrypt(content, "_1_"+this.enc).toString(this.$CryptoJS.enc.Utf8)
        var intern = JSON.parse(decryptedText); // Array of Objects.
        console.log(intern); // You can index every object
        this.wallets = intern;
        this.showWallet(this.wallets[0].address)
      };
      fileread.readAsText(file_to_read);

      console.log(e);
    },
    showWallet(address){
      this.selectedWallet = address;
    }
  },
  mounted() {
  },
  beforeDestroy() {
    if (this.$rtl.isRTL) {
      this.i18n.locale = 'en';
      this.$rtl.disableRTL();
    }
  }
};
</script>
<style></style>
