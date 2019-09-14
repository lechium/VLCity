/*
* This header is generated by classdump-dyld 1.0
* on Sunday, July 22, 2018 at 11:13:54 PM Mountain Standard Time
* Operating System: Version 11.3 (Build 15L211)
* Image Source: /System/Library/PrivateFrameworks/TVSettingKit.framework/TVSettingKit
* classdump-dyld is licensed under GPLv3, Copyright © 2013-2016 by Elias Limneos.
*/


@class NSIndexSet;

@interface TSKCollectionChange : NSObject {

	unsigned long long _changeKind;
	NSIndexSet* _sourceIndexes;
	NSIndexSet* _destinationIndexes;

}

@property (nonatomic,readonly) unsigned long long changeKind;                     //@synthesize changeKind=_changeKind - In the implementation block
@property (nonatomic,copy,readonly) NSIndexSet * sourceIndexes;                   //@synthesize sourceIndexes=_sourceIndexes - In the implementation block
@property (nonatomic,copy,readonly) NSIndexSet * destinationIndexes;              //@synthesize destinationIndexes=_destinationIndexes - In the implementation block
-(id)init;
-(id)description;
-(id)initWithChangeKind:(unsigned long long)arg1 sourceIndexes:(id)arg2 destinationIndexes:(id)arg3 ;
-(unsigned long long)changeKind;
-(NSIndexSet *)sourceIndexes;
-(NSIndexSet *)destinationIndexes;
@end
