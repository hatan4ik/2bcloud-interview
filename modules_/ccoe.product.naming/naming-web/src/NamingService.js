export const supportedConventions = [
    "default",
    "default_without_dashes",
    "default_with_suffix",
    "virtual_machine",
    "vm_subresource"
]

export const environments = [
    "Production",
    "Test",
    "Development",
    "Lab",
    "Global"
]

export const locationCodeMap = {
    "West Europe": "weu1",
    "East US": "eus1",
    "East US2": "eus2",
    "Global": "glob",
    "Central US": "cus1",
    "North Europe": "neu1",
    "South East Asia": "sea1",
    "UK South": "uks1",
    "Central India": "cin1"
}

const requiredPropertiesAvailable = (props) => {
    let errors = []

    if (props.resourceType === null) {
        errors.push("Missing Resource Type.")
    }
    if (props.location === "") {
        errors.push("Missing Location.")
    }
    if (props.sequenceNumber < 0) {
        errors.push("Missing Sequence Number.")
    }
    if (props.workloadName === "") {
        errors.push("Missing Workload name.")
    }
    if (props.environment === "") {
        errors.push("Missing Environment.")
    }

    return errors
}

const requiredPropertiesForDefaultWithSuffixAvailable = (props) => {
    let errors = requiredPropertiesAvailable(props)
    if (props.suffix === "") {
        errors.push("Missing Suffix.")
    }

    return errors
}

const requiredPropertiesForVMSubResourceSequenceNumberAvailable = (props) => {
    let errors = requiredPropertiesAvailable(props)
    if (props.subResourceSequenceNumber === null) {
        errors.push("Missing Sub resource sequence number.")
    }

    return errors
}

const cleanWorkloadName = (workloadName) => {
    return workloadName.substring(0, 9)
}

const getEnvironmentCode = (environment) => {
    return environment.toLowerCase().substring(0, 1)
}

const getSequenceNumber = (sequenceNumber) => {
    return sequenceNumber.toString().padStart(3, '0')
}

const getTenCharSuffix = (suffix) => {
    return suffix.substring(0, 10)
}

export const getResourceName = (props) => {
    let name = ""
    let errors = requiredPropertiesAvailable(props)
    if (errors.length) {
        return {
            name,
            errors
        }
    }

    const workloadName = cleanWorkloadName(props.workloadName)
    const locationCode = props.locationCode
    const environment = getEnvironmentCode(props.environment)
    const sequenceNumber = getSequenceNumber(props.sequenceNumber)
    const resourceTypeCode = props.resourceType.code

    switch (props.resourceType.convention) {
        case "default_with_suffix":
            name = getNameFromDefaultWithSuffixConvention(resourceTypeCode, workloadName, locationCode, environment, sequenceNumber, props.suffix)
            errors = requiredPropertiesForDefaultWithSuffixAvailable(props)
            break
        case "default_without_dashes":
            name = getNameFromDefaultWithoutDashesConvention(resourceTypeCode, workloadName, locationCode, environment, sequenceNumber)
            break
        case "virtual_machine":
            name = getVirtualMachineName(resourceTypeCode, workloadName, environment, sequenceNumber)
            break
        case "vm_subresource":
            name = getVirtualMachineSubResourceName(resourceTypeCode, workloadName, environment, sequenceNumber, props.subResourceSequenceNumber)
            errors = requiredPropertiesForVMSubResourceSequenceNumberAvailable(props)
            break
        default:
            name = getNameFromDefaultConvention(resourceTypeCode, workloadName, locationCode, environment, sequenceNumber)
            break
    }

    return {
        name,
        errors
    }
}

const getNameFromDefaultConvention = (resourceTypeCode, workloadName, location, environment, sequenceNumber) => {
    return `${resourceTypeCode}-${workloadName}-${location}-${environment}-${sequenceNumber}`
}

const getNameFromDefaultWithoutDashesConvention = (resourceTypeCode, workloadName, location, environment, sequenceNumber) => {
    return `${resourceTypeCode}${workloadName}${location}${environment}${sequenceNumber}`
}

const getNameFromDefaultWithSuffixConvention = (resourceTypeCode, workloadName, location, environment, sequenceNumber, suffix) => {
    const tenCharSuffix = getTenCharSuffix(suffix)
    return `${resourceTypeCode}-${workloadName}-${location}-${environment}-${sequenceNumber}-${tenCharSuffix}`
}

const getVirtualMachineName = (resourceTypeCode, workloadName, environment, sequenceNumber) => {
    return `${resourceTypeCode}${workloadName}${environment}${sequenceNumber}`
}

const getVirtualMachineSubResourceName = (resourceTypeCode, workloadName, environment, sequenceNumber, subResourceSequenceNumber) => {
    const vmName = getVirtualMachineName("vm", workloadName, environment, sequenceNumber)
    const twoDigitsSubResourceSequenceNumber = subResourceSequenceNumber.toString().padStart(2, '0')
    return `${vmName}-${resourceTypeCode}-${twoDigitsSubResourceSequenceNumber}`
}