//
//  Constants.h
//  appliedHISP
//
//  Created by Robert Larkin on 6/7/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#define APP_NAME @"appliedHISP"

// for NSUserDefaults
#define PROFILE_IS_SET_DEFAULTS_IDENTIFIER @"ProfileSet"
#define CONTACTS_DO_EXIST_DEFAULTS_IDENTIFIER @"ContactsExist"
#define READ_RECEIPTS_ENABLED_DEFAULTS_IDENTIFIER @"readReceiptsEnabled"
#define ENABLE_ADVERTISER_DEFAULTS_IDENTIFIER @"EnableMCNetworkAdvertiser"
#define USE_GROUP_HCBK_DEFAULTS_IDENTIFIER @"UseGroupHCBK"

// for setting index on application launch and changing tabs programatically
#define NEW_CONNECTIONS_TAB 0
#define CONTACTS_TAB 1
#define SETTINGS_TAB 2

// for Segues
#define EDIT_PROFILE_SEGUE_IDENTIFIER @"Edit Profile"
#define VIEW_WEB_CONTENT_SEGUE_IDENTIFIER @"View Web Content"

// for Multipeer Connectivity Network
//
// RFC 6335 text:
//   5.1. Service Name Syntax
//
//     Valid service names are hereby normatively defined as follows:
//
//     o  MUST be at least 1 character and no more than 15 characters long
//     o  MUST contain only US-ASCII [ANSI.X3.4-1986] letters 'A' - 'Z' and
//        'a' - 'z', digits '0' - '9', and hyphens ('-', ASCII 0x2D or
//        decimal 45)
//     o  MUST contain at least one letter ('A' - 'Z' or 'a' - 'z')
//     o  MUST NOT begin or end with a hyphen
//     o  hyphens MUST NOT be adjacent to other hyphens
//
#define MC_NETWORK_SERVICE_TYPE_SHCBK @"applied-shcbk"
#define MC_NETWORK_SERVICE_TYPE_GROUPHCBK @"applied-ghcbk"

#define MC_DID_CHANGE_STATE_NOTIFICATION @"MCDidChangeStateNotification"
#define MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION @"MCDidReceiveNewMessageNotification"
#define MC_DID_RECEIVE_INITIATOR_BROADCAST_NOTIFICATION @"MCDidReceiveInitiatorBroadcastNotification"
#define MC_DID_RECEIVE_MEMBER_BROADCAST_NOTIFICATION @"MCDidReceiveMemberBroadcastNotification"
#define MC_DID_RECEIVE_INDIVDUALLY_ENCRYPTED_MESSAGE_NOTIFICATION @"MCDidReceiveIndividuallyEncyptedMessageNotification"
#define MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION @"MCDidReceivePeerDisconnectedNotification"
#define MC_DID_RECEIVE_SHCBK_NOTIFICATION @"MC_DID_RECEIVE_SHCBK_NOTIFICATION"

// Message types for MC Network
#define MC_MESSAGE_TYPE_SHCBK_HASH 1
#define MC_MESSAGE_TYPE_SHCBK_KEY 2
#define MC_MESSAGE_TYPE_INITIATOR_BROADCAST 3
#define MC_MESSAGE_TYPE_MEMBER_BROADCAST 4
#define MC_MESSAGE_TYPE_INITIATOR_INDIVDUAL_ENCRYPTION 5
#define MC_MESSAGE_TYPE_NEW_MESSAGE 6
#define MC_MESSAGE_TYPE_USER_DISCONNECTED 7
#define MC_MESSAGE_TYPE_READ_RECEIPT 8

// for Notifications
#define NEW_CONTACT_ADDED_NOTIFICATION @"NewContactAddedNotification"
#define MYPROFILE_CHANGE_NOTIFICATION @"MyProfileChangedName"
#define PASSCODE_CLOSED_NOTIFICATION @"PasscodeViewControllerDidClose"
#define PROTOCOL_DID_CHANGE_NOTICICATION @"ProtocolDidChange"

