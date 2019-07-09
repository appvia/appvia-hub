module.exports = {
  test: /\.erb$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: [
    {
      loader: 'rails-erb-loader',
      options: {
        runner: `${
          /^win/.test(process.platform) ? 'ruby ' : ''
        }bin/rails runner`,
        timeoutMs: 20000,
        env: {
          ...process.env,
          DISABLE_SPRING: 1
        }
      }
    }
  ]
};
