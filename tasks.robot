*** Settings ***
Documentation       Template robot main suite.

Library             RPA.PDF    #Saves the order HTML receipt as a PDF file.
#Library    Saves the screenshot of the ordered robot.
#...    Embeds the screenshot of the robot to the PDF receipt.
#...    Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Robocorp.Vault
Library             RPA.Robocloud.Secrets
Library             RPA.FileSystem
Library             Collections
Library             RPA.Tables
Library             BuiltIn
Library             RPA.Desktop
Library             RPA.Archive

#Suite Teardown      Cleanup


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      3x
${GLOBAL_RETRY_INTERVAL}    0.5s
${receipt_dir}              ${OUTPUT_DIR}${/}receipts
${screenshot_dir}           ${OUTPUT_DIR}${/}screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Cleanup

Minimal task
    Log    Done.


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Click Button    Show model info
    Wait Until Page Contains Element    model-info
    ${body_locator}=    Set Variable    id-body-
    Select From List By Value    head    ${row}[Head]
    Click Element    ${body_locator}${row}[Body]
    Input Text When Element Is Visible    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Page Contains Element    robot-preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${filename}=    Set Variable    receipt${row}[Order number].pdf
    Wait Until Element Is Visible    receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${receipt_dir}${/}${filename}
    ${pdffile}=    Set Variable    ${receipt_dir}${/}${filename}
    RETURN    ${pdffile}

Take a screenshot of the robot
    [Arguments]    ${row}
    ${filename2}=    Set Variable    robot${row}[Order number].png
    Wait Until Element Is Visible    robot-preview
    Screenshot    id:robot-preview    ${screenshot_dir}${/}${filename2}
    ${screen}=    Set Variable    ${screenshot_dir}${/}${filename2}
    RETURN    ${screen}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}:align=center
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf    ${pdf}

Go to order another robot
    Wait And Click Button    order-another
    # Wait For Elements State

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Cleanup
    RPA.Browser.Selenium.Close Browser
    Remove Directory    ${receipt_dir}    recursive=True
    Remove Directory    ${screenshot_dir}    recursive=True

