// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';

List<List<String>> contacts = <List<String>>[
  <String>['George Washington', 'Westmoreland County', ' 4/30/1789'],
  <String>['John Adams', 'Braintree', ' 3/4/1797'],
  <String>['Thomas Jefferson', 'Shadwell', ' 3/4/1801'],
  <String>['James Madison', 'Port Conway', ' 3/4/1809'],
  <String>['James Monroe', 'Monroe Hall', ' 3/4/1817'],
  <String>['Andrew Jackson', 'Waxhaws Region South/North', ' 3/4/1829'],
  <String>['John Quincy Adams', 'Braintree', ' 3/4/1825'],
  <String>['William Henry Harrison', 'Charles City County', ' 3/4/1841'],
  <String>['Martin Van Buren', 'Kinderhook New', ' 3/4/1837'],
  <String>['Zachary Taylor', 'Barboursville', ' 3/4/1849'],
  <String>['John Tyler', 'Charles City County', ' 4/4/1841'],
  <String>['James Buchanan', 'Cove Gap', ' 3/4/1857'],
  <String>['James K. Polk', 'Pineville North', ' 3/4/1845'],
  <String>['Millard Fillmore', 'Summerhill New', '7/9/1850'],
  <String>['Franklin Pierce', 'Hillsborough New', ' 3/4/1853'],
  <String>['Andrew Johnson', 'Raleigh North', ' 4/15/1865'],
  <String>['Abraham Lincoln', 'Sinking Spring', ' 3/4/1861'],
  <String>['Ulysses S. Grant', 'Point Pleasant', ' 3/4/1869'],
  <String>['Rutherford B. Hayes', 'Delaware', ' 3/4/1877'],
  <String>['Chester A. Arthur', 'Fairfield', ' 9/19/1881'],
  <String>['James A. Garfield', 'Moreland Hills', ' 3/4/1881'],
  <String>['Benjamin Harrison', 'North Bend', ' 3/4/1889'],
  <String>['Grover Cleveland', 'Caldwell New', ' 3/4/1885'],
  <String>['William McKinley', 'Niles', ' 3/4/1897'],
  <String>['Woodrow Wilson', 'Staunton', ' 3/4/1913'],
  <String>['William H. Taft', 'Cincinnati', ' 3/4/1909'],
  <String>['Theodore Roosevelt', 'New York City New', ' 9/14/1901'],
  <String>['Warren G. Harding', 'Blooming Grove', ' 3/4/1921'],
  <String>['Calvin Coolidge', 'Plymouth', '8/2/1923'],
  <String>['Herbert Hoover', 'West Branch', ' 3/4/1929'],
  <String>['Franklin D. Roosevelt', 'Hyde Park New', ' 3/4/1933'],
  <String>['Harry S. Truman', 'Lamar', ' 4/12/1945'],
  <String>['Dwight D. Eisenhower', 'Denison', ' 1/20/1953'],
  <String>['Lyndon B. Johnson', 'Stonewall', '11/22/1963'],
  <String>['Ronald Reagan', 'Tampico', ' 1/20/1981'],
  <String>['Richard Nixon', 'Yorba Linda', ' 1/20/1969'],
  <String>['Gerald Ford', 'Omaha', 'August 9/1974'],
  <String>['John F. Kennedy', 'Brookline', ' 1/20/1961'],
  <String>['George H. W. Bush', 'Milton', ' 1/20/1989'],
  <String>['Jimmy Carter', 'Plains', ' 1/20/1977'],
  <String>['George W. Bush', 'New Haven', ' 1/20, 2001'],
  <String>['Bill Clinton', 'Hope', ' 1/20/1993'],
  <String>['Barack Obama', 'Honolulu', ' 1/20/2009'],
  <String>['Donald J. Trump', 'New York City', ' 1/20/2017'],
];

class ListItem extends StatelessWidget {
  const ListItem({
    this.name,
    this.place,
    this.date,
    this.called,
  });

  final String name;
  final String place;
  final String date;
  final bool called;

  @override
  Widget build(BuildContext context) {
    return Padding(padding:const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0), child:Container(
      height: 114.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        color: Colors.black.withOpacity(0.1),
      ),
      //   child: Row(
      //     children: <Widget>[
      //       Container(
      //         width: 38.0,
      //         child: called
      //             ? const Align(
      //                 alignment: Alignment.topCenter,
      //                 child: Icon(
      //                   CupertinoIcons.phone_solid,
      //                   color: CupertinoColors.inactiveGray,
      //                   size: 18.0,
      //                 ),
      //               )
      //             : null,
      //       ),
      //       Expanded(
      //         child: Container(
      //           decoration: const BoxDecoration(
      //             border: Border(
      //               bottom: BorderSide(color: Color(0xFFBCBBC1), width: 0.0),
      //             ),
      //           ),
      //           padding:
      //               const EdgeInsets.only(left: 1.0, bottom: 9.0, right: 10.0),
      //           child: Row(
      //             children: <Widget>[
      //               Expanded(
      //                 child: Column(
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                   children: <Widget>[
      //                     Text(
      //                       name,
      //                       maxLines: 1,
      //                       overflow: TextOverflow.ellipsis,
      //                       style: const TextStyle(
      //                         fontWeight: FontWeight.w600,
      //                         letterSpacing: -0.18,
      //                       ),
      //                     ),
      //                     Text(
      //                       place,
      //                       maxLines: 1,
      //                       overflow: TextOverflow.ellipsis,
      //                       style: const TextStyle(
      //                         fontSize: 15.0,
      //                         letterSpacing: -0.24,
      //                         color: CupertinoColors.inactiveGray,
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //               Text(
      //                 date,
      //                 style: const TextStyle(
      //                   color: CupertinoColors.inactiveGray,
      //                   fontSize: 15.0,
      //                   letterSpacing: -0.41,
      //                 ),
      //               ),
      //               const Padding(
      //                 padding: EdgeInsets.only(left: 9.0),
      //                 child: Icon(CupertinoIcons.info,
      //                     color: CupertinoColors.activeBlue),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
    ));
  }
}
