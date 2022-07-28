import { useEthers } from "@usedapp/core"
import helperConfig from "../helper-config.json"
import networkMapping from "../chain-info/deployments/map.json"
//import { constants } from "buffer"
import { constants } from "ethers"
import brownieConfig from "../brownie-config.json"

export const Main = () => {
    // Show token values from the wallet

    // Get address of different tokens
    // Get balance of the users wallet
    // send brownie-config to our 'src' folder
    // send the build folder
    const { chainId } = useEthers()
    const networkName = chainId ? helperConfig[chainId] : "dev"
    
    const dappTokenAddress = chainId ? networkMapping[String(chainId)]["DappToken"][0] : constants.AddressZero
    const wethTokenAddress = chainId ? brownieConfig["networks"][networkName]["weth_token"]// brownie config
    return (<div>Hi!</div>)
}
