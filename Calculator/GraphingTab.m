//
//  GraphingTab.m
//  Calculator
//
//  Created by Thomas Redding on 10/31/14.
//  Copyright (c) 2014 Thomas Redding. All rights reserved.
//

#import "GraphingTab.h"

@implementation GraphingTab

- (Tab*) initWithContentViewBrainAndPreferences: (id) contentView brain: (Brain*) brain preferences: (Preferences*) preferences {
    self.contentView = contentView;
    self.brain = brain;
    self.preferences = preferences;
    
    self.x = 0;
    self.y = 0;
    self.width = 5;
    self.height = 5;
    self.steps = 40;
    
    GraphingFunction *templateA = [[GraphingFunction alloc] initWithBrain:self.brain];
    templateA.string = @"x";
    templateA.index = 0;
    [templateA update:self.x-self.width/2 end:self.x+self.width/2 steps:100];
    GraphingFunction *templateB = [[GraphingFunction alloc] initWithBrain:self.brain];
    templateB.string = @"x^2";
    templateB.index = 1;
    [templateB update:self.x-self.width/2 end:self.x+self.width/2 steps:100];
    GraphingFunction *templateC = [[GraphingFunction alloc] initWithBrain:self.brain];
    templateC.string = @"log(x)";
    templateC.index = 2;
    [templateC update:self.x-self.width/2 end:self.x+self.width/2 steps:100];
    self.formulas = [[NSMutableArray alloc] initWithObjects:templateA, templateB, templateC, nil];
    
    double width = [[self.contentView window] frame].size.width;
    double height = [[self.contentView window] frame].size.height;
    
    self.graphingView = [[GraphingView alloc] init];
    self.graphingView.functionList = self.formulas;
    self.graphingView.x = self.x;
    self.graphingView.y = self.y;
    self.graphingView.width = self.width;
    self.graphingView.height = self.height;
    self.graphingView.preferences = self.preferences;
    [self.graphingView setFrame: NSMakeRect(100, 0, width-100, height-60)];
    [self.graphingView setAutoresizingMask: NSViewMaxXMargin | NSViewWidthSizable | NSViewHeightSizable];
    
    self.currentFunction = [[NSTextField alloc] initWithFrame:NSMakeRect(0, height-60, width, 20)];
    [self.currentFunction setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
    
    // left-side table of formulas
    NSTableColumn *columnVisible = [[NSTableColumn alloc] initWithIdentifier:@"isVisible"];
    NSTableColumn *columnFormula = [[NSTableColumn alloc] initWithIdentifier:@"formula"];
    self.tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
    self.tableView.headerView = nil;
    
    [[columnVisible headerCell] setStringValue:[NSString stringWithFormat:@"isvisible"]];
    [columnVisible setWidth:20];
    NSButtonCell* checkBox = [[NSButtonCell alloc] init];
    [checkBox setSelectable:true];
    [checkBox setButtonType:NSSwitchButton];
    [columnVisible setDataCell:checkBox];
    [self.tableView addTableColumn: columnVisible];
    [columnFormula setWidth:75];
    [self.tableView addTableColumn: columnFormula];
    
    [self.tableView setAllowsMultipleSelection: YES];
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 100, 100, 100)];
    [self.scrollView setDocumentView:self.tableView];
    [self.scrollView setAutoresizingMask: NSViewHeightSizable];
    
    self.tableController = [[GraphingTableController alloc] init];
    self.tableController.list = self.formulas;
    [self.tableView setDataSource: self.tableController];
    [self.tableView setDelegate:self.tableController];
    [self.tableController setParent:self];
    
    self.addButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 60, 50, 20)];
    [self.addButton setTitle:@"+"];
    [self.addButton setTarget:self];
    [self.addButton setAction:@selector(addFunc)];
    
    self.removeButton = [[NSButton alloc] initWithFrame:NSMakeRect(50, 60, 50, 20)];
    [self.removeButton setTitle:@"-"];
    [self.removeButton setTarget:self];
    [self.removeButton setAction:@selector(removeFunc)];
    
    self.selectedRows = [[NSIndexSet alloc] init];
    self.currentFormulaBeingEdited = -1;
    
    return self;
}

- (void) addFunc {
    [self.tableController add];
    [self.tableView reloadData];
}

- (void) removeFunc {
    [self.tableController remove:self.tableView];
    self.selectedRows = [[NSIndexSet alloc] init];
    self.currentFormulaBeingEdited = -1;
    [self.tableView reloadData];
}

- (void) open {
    
    NSLog(@"%i", self.preferences.drawAxes);
    
    [self.contentView addSubview:self.graphingView];
    [self.contentView addSubview:self.currentFunction];
    [self.contentView addSubview:self.scrollView];
    [self.contentView addSubview:self.addButton];
    [self.contentView addSubview:self.removeButton];
    
    double width = [self.contentView window].frame.size.width;
    double height = [self.contentView window].frame.size.height;
    
    [self.graphingView setFrame:NSMakeRect(100, 0, width-100, height-58)];
    [self.currentFunction setFrame:NSMakeRect(0, height-58, width, 20)];
    [self.scrollView setFrame:NSMakeRect(0, 100, 100, height-158)];
    [self.addButton setFrame:NSMakeRect(0, 80, 50, 20)];
    [self.removeButton setFrame:NSMakeRect(50, 80, 50, 20)];
}

- (void) close {
    [self.graphingView removeFromSuperview];
    [self.currentFunction removeFromSuperview];
    [self.scrollView removeFromSuperview];
    [self.addButton removeFromSuperview];
    [self.removeButton removeFromSuperview];
}

- (void) submit {
    //
}

- (void) childToParentMessage: (NSString*) str {
    if([str isEqual: @"cell selected"]) {
        // someone selected or deselected a cell on the table
        // self.selectedRows <- old list of selected cells
        // self.tableView.selectedRowIndexes <- new list of selected cells
        
        // array of changed indices (see the function's coments for details)
        NSMutableArray *changes = [self changedIndex];
        
        
        
        for(int i=0; i<changes.count; i++) {
            if([changes objectAtIndex:i] > 0) {
                // cell 'changes[i]-1' was selected
                int index = [[changes objectAtIndex:i] intValue]-1;
                
                if(self.currentFormulaBeingEdited != -1) {
                    // update old cell being edited
                    [[self.formulas objectAtIndex:self.currentFormulaBeingEdited] setString:self.currentFunction.stringValue];
                    [[self.formulas objectAtIndex:self.currentFormulaBeingEdited] update:self.x-self.width/2 end:self.x+self.width/2 steps:100];
                }
                
                self.currentFormulaBeingEdited = index;
                [self.currentFunction setStringValue:[[self.formulas objectAtIndex:index] string]];
                break;
            }
        }
        [self.tableView reloadData];
    }
    else if([str isEqual: @"checkbox selected"]) {
        // checkbox selected or deselected
    }
}

/*
 this function returns the indices+1 that have changed
 a negative index implies the cell was recently deselected
 a postiive index implies the cell was recently selected
*/
- (NSMutableArray*)changedIndex {
    // A = self.selectedRows
    // B = self.tableView.selectedRowIndexes
    NSMutableArray *rtn = [[NSMutableArray alloc] init];
    for(int i=0; i<self.formulas.count; i++) {
        if([self.selectedRows containsIndex:i]) {
            if([self.tableView.selectedRowIndexes containsIndex:i]) {
                // element of A and B - was selected; still is selected
                // no change
            }
            else {
                // element of A, but not B - was recently deselected
                [rtn addObject: [NSNumber numberWithInt:-1*(i+1)]];
            }
        }
        else {
            if([self.tableView.selectedRowIndexes containsIndex:i]) {
                // element of B, but not A - was recently selected
                [rtn addObject: [NSNumber numberWithInt:i+1]];
            }
            else {
                // not element of A or B - was not selected; still is not selected
                // no change
            }
        }
    }
    return rtn;
}

-(void)updateSelectedRowInfo {
    // this is a copy
    self.selectedRows = self.tableView.selectedRowIndexes;
}

- (void) mouseDown:(NSEvent *)theEvent sender: (int) sender {
    //
}

- (void) mouseUp:(NSEvent *)theEvent {
    //
}

@end