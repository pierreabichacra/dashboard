<template>
  <footer class="footer">
    <div class="container-fluid">
      <ul class="nav">
        <li class="nav-item">
          <a class="nav-link" target="_blank" href="https://etherscan.io">
            etherscan
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" target="_blank" href="https://www.dextools.io/app/en/ether/pair-explorer/0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640">
            Dextools
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" target="_blank" href="https://app.uniswap.org/#/swap">
            Uniswap
          </a>
        </li>
      </ul>
      <div class="copyright">
        {{ today }} {{ now }}
      </div>
    </div>
  </footer>
</template>
<script>
  export default {
    data() {
      return {
        today: new Date().toLocaleDateString(),
        now: new Date().toLocaleTimeString(),
      }
    }
  };
</script>
<style>
</style>
