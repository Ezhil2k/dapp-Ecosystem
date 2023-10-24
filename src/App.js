import './App.css';
import Web3Modal from 'web3modal'; 
import {providers, Contract, ethers} from 'ethers';
import {useEffect, useState, useRef} from 'react'
import { DOGERINU_CONTRACT_ADDRESS, abi  } from './helpers/constants';
import {Toaster, toast} from 'react-hot-toast'
function App() {
  
  const [walletconnected,setWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState("");
  const [accountBalance, setAccountBalance] = useState("");
  const [transferTo, setTransferTo] = useState("");
  const [transferAmount, setTransferAmount] = useState(0);

  const [sending,setSending] = useState(false)


  const web3ModalRef = useRef();

  const getProviderOrSigner = async (needSigner = false) => { 

    const provider = await web3ModalRef.current.connect();
    const web3Provider = new providers.Web3Provider(provider);

    //get the chainId and check if it is the network we want
    const {chainId} = await web3Provider.getNetwork();
    console.log(chainId)
    if (chainId !== 11155111) {
      alert("change network to sepolia");
      throw new Error("change network to sepolia");
    }

    // more priveleged version of the web3Provider that can also send txn to the blockchain
    if (needSigner) {
      const signer = web3Provider.getSigner();
      return signer;
    }

    return web3Provider;
  }

  const handleConnect = async () => {
    try{
      const thesigner = await getProviderOrSigner(true);
      const currentWalletAddress = await thesigner.getAddress();

      setWalletAddress(currentWalletAddress);
      setWalletConnected(true);
      getAccountBalance(currentWalletAddress);
    } catch(err) {
      console.error(err);
    }
  }

  const handleDisconnect = () => {
    setWalletConnected(false);
    setWalletAddress("");
  }

  const getAccountBalance = async (address) => {
    try {
      const provider = await getProviderOrSigner();
      const tokenContract = new Contract(
        DOGERINU_CONTRACT_ADDRESS,
        abi,
        provider
      );

      const _accountBalance = await tokenContract.balanceOf(address.toString());
      setAccountBalance(ethers.utils.formatEther(_accountBalance.toString()));
    } catch (err) {
      console.error(err)
    }
  }

  const sendTokens = async (e) => {
    e.preventDefault();

    if (parseInt(transferAmount) <= 0){
      toast.error("Amount must be greater than 0");
      return;
    }

    if(transferTo === "") {
      toast.error("Address field is empty");
      return;
    }

    const amountToTransfer = ethers.utils.parseEther(transferAmount.toString());

    try{
      const signer = await getProviderOrSigner(true);
      const tokenContract = new Contract(
        DOGERINU_CONTRACT_ADDRESS,
        abi,
        signer
      );

      const transferStatus = await tokenContract.transfer(transferTo, amountToTransfer);
      setSending(true);
      await transferStatus.wait();
      setSending(false);

      const etherScanLink = `https://sepolia.etherscan.io/tx/${transferStatus.hash}`;
      toast.success((t) => (
        <p>Transaction success! check status here: <a rel="noreferrer" target="_blank" href= {etherScanLink}>view block explorer</a></p>
      ), {
        duration: 10000
      });

      getAccountBalance(walletAddress);
      
    } catch (err) {
      toast.error("Error sending tokens.")
    }
  }

  useEffect(() => {
    if(!walletconnected){
      web3ModalRef.current = new Web3Modal({
        network: "sepolia",
        providerOptions: {},
        disableInjectedProvider: false,
      })
    }
  })

  return (
    <div className="App">
      <Toaster/>
      <header className='App-header'>
        <h3>Doger Inu</h3>
        <div className='wrapperDiv'>
        
        {walletconnected ? (
          <>
          <b>Balance:</b> {accountBalance} DGI

          <form className='transferForm' onSubmit={(e) => sendTokens(e)}>
            <div className='formLeft'>
              <input type="text" name='toAddress' value={transferTo} onChange={(e) => setTransferTo(e.target.value)} placeholder="To address"/>
              <input min="0" type='number' name='transferAmount' value={transferAmount} onChange={(e) => setTransferAmount(e.target.value)} placeholder='Amount'/>
            </div>
            <div className='formRight'>
              <button type='submit'>{sending ? 'sending...' : 'send Tokens'}</button>
            </div>
          </form>

          <button className='button' style= {{'backgrounfcolor' : '#e55039'}} onClick={(e) => handleDisconnect(e)}>Disconnect</button>
          </>
        ) : (
          <> 
          <p>Please Connect to your Wallet</p>
          <button className='button' onClick={(e) => handleConnect(e)}>Connect Wallet</button>
          </>
        )}
        </div>
      </header>
    </div>
  );
}

export default App;
